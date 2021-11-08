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
	override func setEditing(_ editing: Bool, animated: Bool) {
		if isEditing {
			// Delete empty groups if we reordered all the items out of them.
			let newViewModel = viewModel.refreshed()
			setViewModelAndMoveRows(newViewModel)
			
			viewModel.context.tryToSave()
		}
		
		super.setEditing(editing, animated: animated)
		
		if FeatureFlag.tabBar {
			setBarButtons(animated: false)
		} else {
			setBarButtons(animated: animated)
		}
		
		if FeatureFlag.tabBar {
			if editing {
				showToolbar()
			} else {
				hideToolbar()
			}
		}
		
		tableView.performBatchUpdates(nil) // Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines). Otherwise, they'll stay the same size until they reload some other time, like after you edit them or scroll them offscreen and back onscreen.
		// During WWDC 2021, I did a lab in UIKit where the Apple engineer said that this is the best practice for doing this.
	}
	
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
		let newViewModel = viewModel.updatedAfterSorting(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil,
			sortOptionLocalizedName: sortOptionLocalizedName)
		setViewModelAndMoveRows(newViewModel)
	}
	
	final func floatSelectedItemsToTopOfSection() {
		let newViewModel = viewModel.updatedAfterFloatingToTopOfSection(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		setViewModelAndMoveRows(newViewModel)
	}
	
	final func sinkSelectedItemsToBottomOfSection() {
		let newViewModel = viewModel.updatedAfterSinkingToBottomOfSection(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		setViewModelAndMoveRows(newViewModel)
	}
	
}
