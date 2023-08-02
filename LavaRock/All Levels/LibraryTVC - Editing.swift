//
//  LibraryTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit

extension LibraryTVC {
	final func sortSelectedOrAll(sortCommand: SortCommand) {
		let newViewModel = viewModel.updatedAfterSorting(
			selectedRows: tableView.selectedIndexPaths.map { $0.row },
			sortCommand: sortCommand)
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	
	final func floatSelected() {
		let newViewModel = viewModel.updatedAfterFloating(
			selectedRowsInAnyOrder: tableView.selectedIndexPaths.map { $0.row }
		)
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	
	final func sinkSelected() {
		let newViewModel = viewModel.updatedAfterSinking(
			selectedRowsInAnyOrder: tableView.selectedIndexPaths.map { $0.row }
		)
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
}
