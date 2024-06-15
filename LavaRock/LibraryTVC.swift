// 2020-04-15

import UIKit
import MusicKit

class LibraryTVC: UITableViewController {
	final var libraryViewModel: LibraryViewModel {
		get {
			if let self = self as? AlbumsTVC {
				return self.albumsViewModel
			}
			return (self as! SongsTVC).songsViewModel
		}
		set {
			if let self = self as? AlbumsTVC {
				self.albumsViewModel = newValue as! AlbumsViewModel
			} else {
				let songsViewModel = newValue as! SongsViewModel
				(self as! SongsTVC).songsViewModel = songsViewModel
			}
		}
	}
	
	private var viewingButtons: [UIBarButtonItem] { [editButtonItem] + __MainToolbar.shared.barButtonItems }
	final var editingButtons: [UIBarButtonItem] = []
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(.grey_oneEighth)
		
		refreshEditingButtons() // For “Edit” button
		setToolbarItems(viewingButtons, animated: false)
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refreshLibraryItemsWhenVisible), name: MusicRepo.mergedChanges, object: nil)
	}
	@objc private func refreshLibraryItemsWhenVisible() {
		guard nil != view.window else {
			needsRefreshLibraryItemsOnViewDidAppear = true
			return
		}
		refreshLibraryItems()
	}
	private var needsRefreshLibraryItemsOnViewDidAppear = false
	
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if needsRefreshLibraryItemsOnViewDidAppear {
			needsRefreshLibraryItemsOnViewDidAppear = false
			refreshLibraryItems()
		}
	}
	private func refreshLibraryItems() {
		Task {
			// WARNING: Is the user in the middle of a content-dependent interaction, like moving or renaming items? If so, wait until they finish before proceeding, or abort that interaction.
			
			let newViewModel = libraryViewModel.withRefreshedData()
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else {
				// The return value was false, meaning either (A) table view animations are already in progress from an earlier execution of this method, so we shouldn’t run the code after the `await` call this time (later, that earlier execution will), or (B) we applied an empty view model, so we don’t need to update any row contents.
				return
			}
			
			// Update the data within each row, which might be outdated.
			tableView.reconfigureRows(at: tableView.allIndexPaths())
		}
	}
	
	// MARK: - Moving rows
	
	// If `newViewModel` is empty, this method pops `self` off the navigation controller and returns early.
	// Otherwise, it returns after completing the animations for moving rows, with a value of whether it’s safe for the caller to continue running code after those animations. If the return value is `false`, there might be another execution of animating rows still in progress, or this view controller might be about to dismiss itself, and callers could disrupt those animations by running code at those times.
	// If `newViewModel` is non-empty, this method also deselects all rows and refreshes editing buttons.
	final func setViewModelAndMoveAndDeselectRowsAndShouldContinue(
		_ newViewModel: LibraryViewModel
	) async -> Bool {
		await withCheckedContinuation { continuation in
			_setViewModelAndMoveAndDeselectRows(newViewModel) { shouldContinue in
				continuation.resume(returning: shouldContinue)
			}
			// If necessary, include code here to run before the continuation.
		}
	}
	private func _setViewModelAndMoveAndDeselectRows(
		_ newViewModel: LibraryViewModel,
		completionIfShouldRun: @escaping (Bool) -> Void // We used to sometimes not run this completion handler, but if you wrapped this method in `withCheckedContinuation` and resumed the continuation during that handler, that leaked `CheckedContinuation`. Hence, this method always runs the completion handler, and callers should pass a completion handler that returns immediately if the parameter is `false`.
	) {
		let oldViewModel = libraryViewModel
		
		libraryViewModel = newViewModel // Can be empty
		
		guard !newViewModel.isEmpty() else {
			completionIfShouldRun(false)
			deleteThenExit()
			return
		}
		
		isAnimatingBatchUpdates += 1
		tableView.performUpdatesFromRowIdentifiers(
			old: oldViewModel.rowIdentifiers(), new: newViewModel.rowIdentifiers()
		) {
			// Completion handler
			self.isAnimatingBatchUpdates -= 1
			if self.isAnimatingBatchUpdates == 0 { // If we call `performBatchUpdates` multiple times quickly, executions after the first one can beat the first one to the completion closure, because they don’t have to animate any rows. Here, we wait for the animations to finish before we run the completion closure (once).
				completionIfShouldRun(true)
			} else {
				completionIfShouldRun(false)
			}
		}
		
		tableView.deselectAllRows(animated: true)
		refreshEditingButtons()
	}
	private func deleteThenExit() {
		isAnimatingBatchUpdates += 1
		tableView.performBatchUpdates {
			tableView.deleteRows(at: tableView.allIndexPaths(), with: .middle)
		} completion: { _ in
			self.isAnimatingBatchUpdates -= 1
			if self.isAnimatingBatchUpdates == 0 {
				self.dismiss(animated: true) {
					self.navigationController?.popViewController(animated: true)
				}
			}
		}
		
		setEditing(false, animated: true)
	}
	private var isAnimatingBatchUpdates = 0
	
	// MARK: - Editing
	
	// Overrides should call super (this implementation).
	override func setEditing(_ editing: Bool, animated: Bool) {
		if !editing {
			// As of iOS 17.3 developer beta 1, by default, `UITableViewController` deselects rows during `setEditing`, but without animating them.
			// As of iOS 17.3 developer beta 1, to animate deselecting rows, you must do so before `super.setEditing`, not after.
			tableView.deselectAllRows(animated: true)
			
			Database.viewContext.tryToSave()
		}
		
		super.setEditing(editing, animated: animated)
		
		refreshEditingButtons()
		setToolbarItems(editing ? editingButtons : viewingButtons, animated: animated)
		
		// As of iOS 17.5 developer beta 1, we still have to do this to resize cells in case text wrapped. During a WWDC 2021 lab, a UIKit engineer told me that this is the best practice for doing that.
		// As of iOS 15.4 developer beta 1, you must do this after `super.setEditing`, not before.
		tableView.performBatchUpdates(nil)
	}
	
	// Overrides should call super (this implementation).
	func refreshEditingButtons() {
		editButtonItem.isEnabled = !libraryViewModel.isEmpty() && MusicAuthorization.currentStatus == .authorized // If the user revokes access, we’re showing the placeholder, but the view model is probably non-empty.
		editButtonItem.image = isEditing
		? UIImage(systemName: "checkmark.circle.fill")
		: UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))
	}
	
	// MARK: - Table view
	
	override func tableView(
		_ tableView: UITableView, didSelectRowAt indexPath: IndexPath
	) {
		// As of iOS 17.5 RC, UIKit calls this when the user selects a row, but not when our program calls `selectRow`.
		if isEditing {
			refreshEditingButtons()
		}
	}
	final override func tableView(
		_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath
	) {
		// As of iOS 17.5 RC, UIKit calls this when the user deselects a row, but not when our program calls `deselectRow`.
		refreshEditingButtons()
	}
}
