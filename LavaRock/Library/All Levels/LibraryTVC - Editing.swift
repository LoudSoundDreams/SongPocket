//
//  LibraryTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension LibraryTVC {
	
	// Overrides should call super (this implementation).
	override func setEditing(_ editing: Bool, animated: Bool) {
		if isEditing {
			// Delete empty groups if we reordered all the items out of them.
			let newViewModel = viewModel.updatedWithRefreshedData()
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
		
		tableView.performBatchUpdates(nil) // Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines). Otherwise, they’ll stay the same size until they reload some other time, like after you edit them or scroll them offscreen and back onscreen.
		// During a WWDC 2021 lab, a UIKit engineer said that this is the best practice for doing that.
	}
	
	final func makeSortOptionsMenu() -> UIMenu {
		let groupedElements: [[UIMenuElement]] = sortOptionsGrouped.map { sortOptionGroup in
			let groupOfChildren: [UIMenuElement] = sortOptionGroup.map { sortOption in
				let action = UIAction(
					title: sortOption.localizedName()
				) { action in
					self.sortSelectedOrAllItems(sortOptionLocalizedName: action.title)
				}
				
				return UIDeferredMenuElement.uncached({ useMenuElements in
					let allowed: Bool = {
						let viewModel = self.viewModel
						let indexPathsToSort = viewModel.unsortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
							selectedIndexPaths: self.tableView.indexPathsForSelectedRowsNonNil)
						let items = indexPathsToSort.map { viewModel.itemNonNil(at: $0) }
						return viewModel.allowsSortOption(sortOption, forItems: items)
					}()
					action.attributes = allowed ? [] : .disabled
					useMenuElements([action])
				})
			}
			return groupOfChildren
		}
		
		return UIMenu(
			presentsUpward: true,
			groupedElements: groupedElements)
	}
	
	private func sortSelectedOrAllItems(sortOptionLocalizedName: String) {
		let newViewModel = viewModel.updatedAfterSorting(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil,
			sortOptionLocalizedName: sortOptionLocalizedName)
		setViewModelAndMoveRows(newViewModel)
	}
	
	final func floatSelectedItemsToTopOfSection() {
		let newViewModel = viewModel.updatedAfterFloatingToTopsOfSections(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		setViewModelAndMoveRows(newViewModel)
	}
	
	final func sinkSelectedItemsToBottomOfSection() {
		let newViewModel = viewModel.updatedAfterSinkingToBottomsOfSections(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		setViewModelAndMoveRows(newViewModel)
	}
	
}
