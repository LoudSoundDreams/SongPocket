//
//  LibraryTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit

extension LibraryTVC {
	final func sortSelectedOrAllItems(sortOptionLocalizedName: String) {
		let newViewModel = viewModel.updatedAfterSorting(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil,
			sortOptionLocalizedName: sortOptionLocalizedName)
		Task {
			let _ = await setViewModelAndMoveRowsAndShouldContinue(newViewModel)
		}
	}
	
	final func floatSelectedItemsToTopOfSection() {
		let newViewModel = viewModel.updatedAfterFloatingToTopsOfSections(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		Task {
			let _ = await setViewModelAndMoveRowsAndShouldContinue(newViewModel)
		}
	}
	
	final func sinkSelectedItemsToBottomOfSection() {
		let newViewModel = viewModel.updatedAfterSinkingToBottomsOfSections(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		Task {
			let _ = await setViewModelAndMoveRowsAndShouldContinue(newViewModel)
		}
	}
}
