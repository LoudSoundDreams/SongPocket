// 2020-04-15

import UIKit
import MusicKit

class LibraryTVC: UITableViewController {
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
	func refreshLibraryItems() {
		fatalError()
		
		// WARNING: Is the user in the middle of a content-dependent interaction, like moving or renaming items? If so, wait until they finish before proceeding, or abort that interaction.
	}
	
	// MARK: - Moving rows
	
	// Returns a boolean indicating whether it’s safe for the caller to continue running code. If it’s `false`, table view animations are already in progress from an earlier call of this method, and callers could disrupt those animations by running further code.
	// Returns after completing the animations for moving rows, and also deselects all rows and refreshes editing buttons.
	final func moveRows(
		oldIdentifiers: [AnyHashable],
		newIdentifiers: [AnyHashable],
		runningBeforeContinuation: (() -> Void)? = nil
	) async -> Bool {
		await withCheckedContinuation { continuation in
			_moveRows(oldIdentifiers: oldIdentifiers, newIdentifiers: newIdentifiers) { shouldContinue in
				continuation.resume(returning: shouldContinue)
			}
			runningBeforeContinuation?()
		}
	}
	private func _moveRows(
		oldIdentifiers: [AnyHashable],
		newIdentifiers: [AnyHashable],
		completionIfShouldRun: @escaping (Bool) -> Void // We used to sometimes not run this completion handler, but if you wrapped this method in `withCheckedContinuation` and resumed the continuation during that handler, that leaked `CheckedContinuation`. Hence, this method always runs the completion handler, and callers should pass a completion handler that returns immediately if the parameter is `false`.
	) {
		isAnimatingReflectViewModel += 1
		tableView.performUpdatesFromRowIdentifiers(old: oldIdentifiers, new: newIdentifiers) {
			// Completion handler
			self.isAnimatingReflectViewModel -= 1
			if self.isAnimatingReflectViewModel == 0 { // If we call `performBatchUpdates` multiple times quickly, executions after the first one can beat the first one to the completion closure, because they don’t have to animate any rows. Here, we wait for the animations to finish before we run the completion closure (once).
				completionIfShouldRun(true)
			} else {
				completionIfShouldRun(false)
			}
		}
	}
	private var isAnimatingReflectViewModel = 0
	
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
