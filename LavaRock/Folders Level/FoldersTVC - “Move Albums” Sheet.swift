//
//  FoldersTVC - “Move Albums” Sheet.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit

extension FoldersTVC {
	func createAndOpen() {
		guard
			case .movingAlbums = purpose,
			let foldersViewModel = viewModel as? FoldersViewModel
		else { return }
		
		let newViewModel = foldersViewModel.updatedAfterCreating()
		Task {
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else { return }
			
			renameAndOpenCreated()
		}
	}
	
	func revertCreate() {
		guard case .movingAlbums = purpose else {
			fatalError()
		}
		
		let foldersViewModel = viewModel as! FoldersViewModel
		
		let newViewModel = foldersViewModel.updatedAfterDeletingNewFolder()
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	
	private func renameAndOpenCreated() {
		let foldersViewModel = viewModel as! FoldersViewModel
		
		let indexPath = IndexPath(row: FoldersViewModel.indexOfNewFolder, section: 0)
		
		let didChangeTitle = foldersViewModel.renameAndReturnDidChangeTitle(
			at: indexPath,
			proposedTitle: nil)
		
		Task {
			if didChangeTitle {
				await tableView.performBatchUpdates__async {
					self.tableView.reloadRows(at: [indexPath], with: .fade)
				}
			}
			
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			performSegue(withIdentifier: "Open Folder", sender: self)
		}
	}
}
