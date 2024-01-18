//
//  LibraryTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit

extension LibraryTVC {
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
		
		freshenEditingButtons() // If you made selected rows non-contiguous, that should disable the “Sort” button. If you made all the selected rows contiguous, that should enable the “Sort” button.
	}
	
	// MARK: - Selecting
	
	final override func tableView(
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
			freshenEditingButtons()
		}
	}
	
	final override func tableView(
		_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath
	) {
		if let cell = tableView.cellForRow(at: indexPath) {
			cell.accessibilityTraits.subtract(.selected)
		}
		freshenEditingButtons()
	}
}
