// 2020-04-15

import UIKit
import MusicKit

extension UITableViewCell {
	final func backgroundColors_configureForLibraryItem() {
		backgroundColor = .clear
		selectedBackgroundView = {
			let result = UIView()
			result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
			return result
		}()
	}
}

class LibraryTVC: UITableViewController {
	final lazy var viewModel: LibraryViewModel = AlbumsViewModel()
	
	private var viewingButtons: [UIBarButtonItem] { [editButtonItem] + __MainToolbar.shared.barButtonItems }
	final var editingButtons: [UIBarButtonItem] = []
	private(set) final lazy var floatButton = UIBarButtonItem(title: LRString.moveToTop, image: UIImage(systemName: "arrow.up.to.line"), primaryAction: UIAction { [weak self] _ in self?.floatSelected() })
	private func floatSelected() {
		let unorderedIndices = tableView.selectedIndexPaths.map {
			viewModel.itemIndex(forRow: $0.row)
		}
		
		var newItems = viewModel.items
		newItems.move(fromOffsets: IndexSet(unorderedIndices), toOffset: 0)
		
		var newViewModel = viewModel
		newViewModel.items = newItems
		Task { let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) }
	}
	private(set) final lazy var sinkButton = UIBarButtonItem(title: LRString.moveToBottom, image: UIImage(systemName: "arrow.down.to.line"), primaryAction: UIAction { [weak self] _ in self?.sinkSelected() })
	private func sinkSelected() {
		let unorderedIndices = tableView.selectedIndexPaths.map {
			viewModel.itemIndex(forRow: $0.row)
		}
		
		var newItems = viewModel.items
		newItems.move(fromOffsets: IndexSet(unorderedIndices), toOffset: newItems.count)
		
		var newViewModel = viewModel
		newViewModel.items = newItems
		Task { let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) }
	}
	
	private var needsRefreshLibraryItemsOnViewDidAppear = false
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(LRColor.grey_oneEighth)
		
		refreshEditingButtons() // For “Edit” button
		setToolbarItems(viewingButtons, animated: false)
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refreshLibraryItemsWhenVisible), name: .LRMergedChanges, object: nil)
	}
	@objc private func refreshLibraryItemsWhenVisible() {
		guard view.window != nil else {
			needsRefreshLibraryItemsOnViewDidAppear = true
			return
		}
		refreshLibraryItems()
	}
	
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if needsRefreshLibraryItemsOnViewDidAppear {
			needsRefreshLibraryItemsOnViewDidAppear = false
			refreshLibraryItems()
		}
	}
	
	// MARK: - Library items
	
	private func refreshLibraryItems() {
		Task {
			/*
			 The user might currently be in the middle of a content-dependent task, which refreshing would affect the consequences of.
			 • “Sort” menu (`LibraryTVC`)
			 • Song actions, including overflow menu (`SongsTVC`)
			 */
			await view.window?.rootViewController?.dismiss__async(animated: true)
			
			let newViewModel = viewModel.withRefreshedData()
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else {
				// The return value was false, meaning either (A) table view animations are already in progress from an earlier execution of this method, so we shouldn’t run the code after the `await` call this time (later, that earlier execution will), or (B) we applied an empty view model, so we don’t need to update any row contents.
				return
			}
			
			// Update the data within each row, which might be outdated.
			tableView.reconfigureRows(at: tableView.allIndexPaths())
		}
	}
	
	// Returns after completing the animations for moving rows, with a value of whether it’s safe for the caller to continue running code after those animations. If the return value is `false`, there might be another execution of animating rows still in progress, or this view controller might be about to dismiss itself, and callers could disrupt those animations by running code at those times.
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
		let oldViewModel = viewModel
		
		viewModel = newViewModel // Can be empty
		
		guard !newViewModel.items.isEmpty else {
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
		editButtonItem.isEnabled = MusicAuthorization.currentStatus == .authorized && !viewModel.items.isEmpty
		editButtonItem.image = (
			isEditing
			? UIImage(systemName: "checkmark.circle.fill")
			: UIImage(systemName: "checkmark.circle")
		)
		let allowsFloatAndSink: Bool = {
			guard !viewModel.items.isEmpty else { return false }
			return !tableView.selectedIndexPaths.isEmpty
		}()
		floatButton.isEnabled = allowsFloatAndSink
		sinkButton.isEnabled = allowsFloatAndSink
	}
	final func allowsArrange() -> Bool {
		guard !viewModel.items.isEmpty else { return false }
		let selected = tableView.selectedIndexPaths
		if selected.isEmpty {
			return true
		}
		return selected.map { $0.row }.sorted().isConsecutive()
	}
	final func arrangeSelectedOrAll(by command: ArrangeCommand) {
		var newViewModel = viewModel
		newViewModel.items = {
			let subjectedIndicesInOrder = selectedOrAllIndices().sorted()
			let toSort = subjectedIndicesInOrder.map { viewModel.items[$0] }
			let sorted = command.apply(to: toSort)
			var result = viewModel.items
			subjectedIndicesInOrder.indices.forEach { counter in
				let replaceAt = subjectedIndicesInOrder[counter]
				let newItem = sorted[counter]
				result[replaceAt] = newItem
			}
			return result
		}()
		Task { let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) }
	}
	final func selectedOrAllIndices() -> [Int] {
		let selected = tableView.selectedIndexPaths
		guard !selected.isEmpty else { return viewModel.items.indices.map { $0 } }
		return selected.map { viewModel.itemIndex(forRow: $0.row) }
	}
	
	// MARK: - Table view
	
	final override func tableView(
		_ tableView: UITableView,
		moveRowAt fromIndexPath: IndexPath,
		to: IndexPath
	) {
		let fromIndex = viewModel.itemIndex(forRow: fromIndexPath.row)
		let toIndex = viewModel.itemIndex(forRow: to.row)
		
		var newItems = viewModel.items
		let itemBeingMoved = newItems.remove(at: fromIndex)
		newItems.insert(itemBeingMoved, at: toIndex)
		viewModel.items = newItems
		
		refreshEditingButtons() // If you made selected rows non-contiguous, that should disable the “Sort” button. If you made all the selected rows contiguous, that should enable the “Sort” button.
	}
	
	override func tableView(
		_ tableView: UITableView, didSelectRowAt indexPath: IndexPath
	) {
		if isEditing {
			refreshEditingButtons()
		}
	}
	final override func tableView(
		_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath
	) {
		refreshEditingButtons()
	}
}
