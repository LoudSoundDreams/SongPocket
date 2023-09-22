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
			!clipboard.hasCreatedNewFolder,
			let foldersViewModel = viewModel as? FoldersViewModel
		else { return }
		clipboard.hasCreatedNewFolder = true
		
		let newViewModel = foldersViewModel.updatedAfterCreating()
		Task {
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else { return }
			
			openCreated()
		}
	}
	private func openCreated() {
		let indexPath = IndexPath(row: FoldersViewModel.indexOfNewFolder, section: 0)
		tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		performSegue(withIdentifier: "Open Folder", sender: self)
	}
	
	func revertCreate() {
		guard case .movingAlbums(let clipboard) = purpose else {
			fatalError()
		}
		clipboard.hasCreatedNewFolder = false
		
		let foldersViewModel = viewModel as! FoldersViewModel
		
		let newViewModel = foldersViewModel.updatedAfterDeletingNewFolder()
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
}
