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
		_ tableView: UITableView,
		canEditRowAt indexPath: IndexPath
	) -> Bool {
		return indexPath.row >= numberOfRowsAboveLibraryItemsInSection
	}
	
	// MARK: Reordering
	
	final override func tableView(
		_ tableView: UITableView,
		moveRowAt fromIndexPath: IndexPath,
		to: IndexPath
	) {
		let fromItemIndex = indexOfLibraryItem(for: fromIndexPath)
		let toItemIndex = indexOfLibraryItem(for: to)
		
		let itemBeingMoved = sectionOfLibraryItems.items[fromItemIndex]
		var newItems = sectionOfLibraryItems.items
		newItems.remove(at: fromItemIndex)
		newItems.insert(itemBeingMoved, at: toItemIndex)
		sectionOfLibraryItems.setItems(newItems)
		
		didChangeRowsOrSelectedRows() // If you made selected rows non-contiguous, that should disable the "Sort" button. If you made all the selected rows contiguous, that should enable the "Sort" button.
	}
	
	final override func tableView(
		_ tableView: UITableView,
		targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
		toProposedIndexPath proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
		if proposedDestinationIndexPath.row < numberOfRowsAboveLibraryItemsInSection {
			return indexPathFor(
				indexOfLibraryItem: 0,
				indexOfSectionOfLibraryItem: proposedDestinationIndexPath.section)
		} else {
			return proposedDestinationIndexPath
		}
	}
	
	// MARK: - Selecting
	
	// Overrides of this method should call super (this implementation).
	override func tableView(
		_ tableView: UITableView,
		shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) -> Bool {
		guard indexPath.row >= numberOfRowsAboveLibraryItemsInSection else {
			return false
		}
		return true
	}

	final override func tableView(
		_ tableView: UITableView,
		didBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) {
		if !isEditing {
			setEditing(true, animated: true) // As of iOS 14.7 beta 2, with LavaRock's codebase as of build 144, starting a multiple-selection interaction sometimes causes the table view to crash when our override of setEditing calls tableView.performBatchUpdates(nil), with "[Assert] Attempted to call -cellForRowAtIndexPath: on the table view while it was in the process of updating its visible cells, which is not allowed."
			// During WWDC 2021, I did a lab in UIKit where the Apple engineer was pretty sure that this was a bug in UITableView.
			// By checking isEditing first, we either prevent that or make it very rare.
		}
	}
	
	// To disable selection for a row, it's simpler to set cell.isUserInteractionEnabled = false.
	// However, you can begin a multiple-selection interaction on a cell that does allow user interaction and shouldBeginMultipleSelectionInteractionAt, and swipe over a cell that doesn't allow user interaction, to select it too.
	// Therefore, if you support multiple-selection interactions, you must use this method to disable selection for certain rows.
	final override func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		guard indexPath.row >= numberOfRowsAboveLibraryItemsInSection else {
			return nil
		}
		return indexPath
	}
	
	// Overrides of this method should call super (this implementation).
	override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
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
		_ tableView: UITableView,
		didDeselectRowAt indexPath: IndexPath
	) {
		if let cell = tableView.cellForRow(at: indexPath) {
			cell.accessibilityTraits.subtract(.selected)
		}
		didChangeRowsOrSelectedRows()
	}
	
}
