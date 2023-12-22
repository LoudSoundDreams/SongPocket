//
//  LibraryTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit

extension LibraryTVC {
	// MARK: - Editing
	
	final override func tableView(
		_ tableView: UITableView, canEditRowAt indexPath: IndexPath
	) -> Bool {
		return viewModel.pointsToSomeItem(row: indexPath.row)
	}
	
	// MARK: Reordering
	
	final override func tableView(
		_ tableView: UITableView,
		targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
		toProposedIndexPath proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
		if viewModel.pointsToSomeItem(row: proposedDestinationIndexPath.row) {
			return proposedDestinationIndexPath
		}
		
		// Reordering upward
		if proposedDestinationIndexPath < sourceIndexPath {
			return IndexPath(
				row: viewModel.row(forItemIndex: 0),
				section: proposedDestinationIndexPath.section)
		}
		
		// Reordering downward
		return proposedDestinationIndexPath
	}
	
	final override func tableView(
		_ tableView: UITableView,
		moveRowAt fromIndexPath: IndexPath,
		to: IndexPath
	) {
		let fromIndex = viewModel.itemIndex(forRow: fromIndexPath.row)
		let toIndex = viewModel.itemIndex(forRow: to.row)
		
		var newItems = viewModel.libraryGroup().items
		let itemBeingMoved = newItems.remove(at: fromIndex)
		newItems.insert(itemBeingMoved, at: toIndex)
		viewModel.groups[0].items = newItems
		
		didChangeRowsOrSelectedRows() // If you made selected rows non-contiguous, that should disable the “Sort” button. If you made all the selected rows contiguous, that should enable the “Sort” button.
	}
	
	// MARK: - Selecting
	
	// Overrides should call super (this implementation) as a last resort.
	override func tableView(
		_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) -> Bool {
		return viewModel.pointsToSomeItem(row: indexPath.row)
	}
	
	final override func tableView(
		_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) {
		if !isEditing {
			setEditing(true, animated: true) // As of iOS 14.7 developer beta 2 and LavaRock build 144, starting a multiple-selection interaction sometimes causes the table view to crash when our override of `setEditing` calls `tableView.performBatchUpdates(nil)`, with “[Assert] Attempted to call -cellForRowAtIndexPath: on the table view while it was in the process of updating its visible cells, which is not allowed.”
			// During a WWDC 2021 lab, a UIKit engineer told me that this seemed like a bug in `UITableView`.
			// By checking `isEditing` first, we either prevent that or make it very rare.
		}
	}
	
	// Overrides should call super (this implementation) as a last resort.
	// To disable selection for a row, it’s simpler to set `cell.isUserInteractionEnabled = false`.
	// However, you can begin a multiple-selection interaction on a cell that does allow user interaction and `shouldBeginMultipleSelectionInteractionAt`, and swipe over a cell that doesn’t allow user interaction, to select it too.
	// Therefore, if you support multiple-selection interactions, you must use this method to disable selection for certain rows.
	override func tableView(
		_ tableView: UITableView, willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		return viewModel.pointsToSomeItem(row: indexPath.row) ? indexPath : nil
	}
	
	// Overrides should call super (this implementation) if `viewModel.pointsToSomeItem(indexPath)`.
	override func tableView(
		_ tableView: UITableView, didSelectRowAt indexPath: IndexPath
	) {
		if isEditing {
			if let cell = tableView.cellForRow(at: indexPath) {
				cell.accessibilityTraits.formUnion(.selected)
			}
			didChangeRowsOrSelectedRows()
		}
	}
	
	// MARK: Deselecting
	
	final override func tableView(
		_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath
	) {
		if let cell = tableView.cellForRow(at: indexPath) {
			cell.accessibilityTraits.subtract(.selected)
		}
		didChangeRowsOrSelectedRows()
	}
}
