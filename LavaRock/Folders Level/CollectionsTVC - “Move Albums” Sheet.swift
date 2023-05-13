//
//  CollectionsTVC - “Move Albums” Sheet.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit

extension CollectionsTVC {
	func createAndOpen() {
		guard
			case .movingAlbums = purpose,
			let collectionsViewModel = viewModel as? CollectionsViewModel
		else { return }
		
		let newViewModel = collectionsViewModel.updatedAfterCreating()
		Task {
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else { return }
			
			renameAndOpenCreated()
		}
	}
	
	func revertCreate() {
		guard case .movingAlbums = purpose else {
			fatalError()
		}
		
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		let newViewModel = collectionsViewModel.updatedAfterDeletingNewCollection()
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	
	private func renameAndOpenCreated() {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		let indexPath = collectionsViewModel.indexPathOfNewCollection
		
		let didChangeTitle = collectionsViewModel.renameAndReturnDidChangeTitle(
			at: indexPath,
			proposedTitle: nil)
		
		Task {
			if didChangeTitle {
				await tableView.performBatchUpdates__async {
					self.tableView.reloadRows(at: [indexPath], with: .fade)
				}
			}
			
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			performSegue(withIdentifier: "Open Collection", sender: self)
		}
	}
}
