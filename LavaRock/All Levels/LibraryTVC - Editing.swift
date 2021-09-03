//
//  LibraryTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension LibraryTVC {
	
	// Overrides of this method should call super (this implementation).
//	override func setEditing(_ editing: Bool, animated: Bool) {
	final override func setEditing(_ editing: Bool, animated: Bool) {
		if isEditing {
			viewModel.context.tryToSave()
		}
		
		super.setEditing(editing, animated: animated)
		
		setBarButtons(animated: animated)
		
		tableView.performBatchUpdates(nil) // Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines). Otherwise, they'll stay the same size until they reload some other time, like after you edit them or scroll them offscreen and back onscreen.
		// During WWDC 2021, I did a lab in UIKit where the Apple engineer said that this is the best practice for doing this.
	}
	
	// MARK: - Sorting
	
	final func sortOptionsMenu() -> UIMenu {
		let groupedChildren: [[UIAction]] = sortOptionsGrouped.map { sortOptionGroup in
			let groupOfChildren = sortOptionGroup.map { sortOption in
				UIAction(
					title: sortOption.localizedName()
				) { action in
					self.sortSelectedOrAllItems(sortOptionLocalizedName: action.title)
				}
			}
			return groupOfChildren
		}
		return UIMenu(
			presentsUpward: true,
			groupedChildren: groupedChildren)
	}
	
	private func sortSelectedOrAllItems(sortOptionLocalizedName: String) {
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil
		guard let (newItems, section) = viewModel.itemsAndSectionAfterSorting(
			selectedIndexPaths: selectedIndexPaths,
			sortOptionLocalizedName: sortOptionLocalizedName)
		else { return }
		
		setItemsAndMoveRows(
			newItems: newItems,
			section: section
		) {
			self.tableView.deselectAllRows(animated: true)
			self.didChangeRowsOrSelectedRows()
		}
	}
	
	// MARK: - Moving to Top
	
	final func floatSelectedItemsToTopOfSection() {
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil
		guard let (newItems, section) = viewModel.itemsAndSectionAfterFloatingSelectedItemsToTop(
			selectedIndexPaths: selectedIndexPaths)
		else { return }
		
		setItemsAndMoveRows(
			newItems: newItems,
			section: section
		) {
			self.tableView.deselectAllRows(animated: true)
			self.didChangeRowsOrSelectedRows()
		}
	}
	
	// MARK: - Moving to Bottom
	
	final func sinkSelectedItemsToBottomOfSection() {
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil
		guard let (newItems, section) = viewModel.itemsAndSectionAfterSinkingSelectedItemsToBottom(
			selectedIndexPaths: selectedIndexPaths)
		else { return }
		
		setItemsAndMoveRows(
			newItems: newItems,
			section: section
		) {
			self.tableView.deselectAllRows(animated: true)
			self.didChangeRowsOrSelectedRows()
		}
	}
	
}
