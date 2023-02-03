//
//  LibraryTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit

extension LibraryTVC {
	final func sortSelectedOrAllItems(sortCommandLocalizedName: String) {
		let newViewModel = viewModel.updatedAfterSorting(
			selectedIndexPaths: tableView.selectedIndexPaths,
			sortCommandLocalizedName: sortCommandLocalizedName)
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	
	final func floatSelectedItemsToTopOfSection() {
		let newViewModel = viewModel.updatedAfterFloatingToTopsOfSections(
			selectedIndexPaths: tableView.selectedIndexPaths)
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	
	final func sinkSelectedItemsToBottomOfSection() {
		let newViewModel = viewModel.updatedAfterSinkingToBottomsOfSections(
			selectedIndexPaths: tableView.selectedIndexPaths)
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
}
