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
			case .movingAlbums(let clipboard) = purpose,
			!clipboard.hasCreatedNewCollection,
			let collectionsViewModel = viewModel as? CollectionsViewModel
		else { return }
		clipboard.hasCreatedNewCollection = true
		
		let newViewModel = collectionsViewModel.updatedAfterCreating()
		Task {
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else { return }
			
			openCreated()
		}
	}
	private func openCreated() {
		let indexPath = IndexPath(row: CollectionsViewModel.indexOfNewCollection, section: 0)
		tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		performSegue(withIdentifier: "Open Collection", sender: self)
	}
	
	func revertCreate() {
		guard case .movingAlbums(let clipboard) = purpose else {
			fatalError()
		}
		clipboard.hasCreatedNewCollection = false
		
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		let newViewModel = collectionsViewModel.updatedAfterDeletingNewCollection()
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
}
