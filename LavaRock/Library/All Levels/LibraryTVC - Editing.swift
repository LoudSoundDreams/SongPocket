//
//  LibraryTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension LibraryTVC {
	
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
