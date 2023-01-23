//
//  CollectionsTVC - “Move Albums” Sheet.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit

extension CollectionsTVC {
	func createAndPrompt() {
		guard
			case let .movingAlbums(clipboard) = purpose,
			!clipboard.didAlreadyCreate, // Without this, if you’re fast, you can tap “Save” to create a new `Collection`, then tap “New Collection” to bring up another dialog before we open the first `Collection` you made. You must reset `didAlreadyCreate = false` both during reverting and if we exit the empty new `Collection`.
			let collectionsViewModel = viewModel as? CollectionsViewModel
		else { return }
		
		clipboard.didAlreadyCreate = true
		
		let newViewModel = collectionsViewModel.updatedAfterCreating()
		Task {
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else { return }
			
			renameAndOpenCreated(proposedTitle: nil)
		}
	}
	
	func revertCreate() {
		guard case let .movingAlbums(clipboard) = purpose else {
			fatalError()
		}
		
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		clipboard.didAlreadyCreate = false
		
		let newViewModel = collectionsViewModel.updatedAfterDeletingNewCollection()
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	
	private func renameAndOpenCreated(proposedTitle: String?) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		let indexPath = collectionsViewModel.indexPathOfNewCollection
		
		let didChangeTitle = collectionsViewModel.renameAndReturnDidChangeTitle(
			at: indexPath,
			proposedTitle: proposedTitle)
		
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
