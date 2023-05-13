//
//  FoldersTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension FoldersTVC: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		textField.selectAll(nil) // As of iOS 15.3 developer beta 1, the selection works but the highlight doesn’t appear if `textField.text` is long.
	}
}
extension FoldersTVC {
	// MARK: Renaming
	
	func promptRename(at indexPath: IndexPath) {
		guard let folder = viewModel.itemNonNil(at: indexPath) as? Collection else { return }
		
		let rowWasSelectedBeforeRenaming = tableView.selectedIndexPaths.contains(indexPath)
		
		let dialog = UIAlertController.make_Rename_dialog(
			existing_title: folder.title,
			textFieldDelegate: self,
			done_handler: { [weak self] textFieldText in
				self?.commitRename(
					at: indexPath,
					proposedTitle: textFieldText,
					thenSelectIf: rowWasSelectedBeforeRenaming)
			}
		)
		present(dialog, animated: true)
	}
	
	private func commitRename(
		at indexPath: IndexPath,
		proposedTitle: String?,
		thenSelectIf shouldSelectRow: Bool
	) {
		let foldersViewModel = viewModel as! FoldersViewModel
		
		let _ = foldersViewModel.renameAndReturnDidChangeTitle(
			at: indexPath,
			proposedTitle: proposedTitle)
		
		viewModel.context.tryToSave()
		
		Task {
			await tableView.performBatchUpdates__async {
				self.tableView.reloadRows(at: [indexPath], with: .fade)
			} runningBeforeContinuation: {
				if shouldSelectRow {
					self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
				}
			}
		}
	}
	
	// MARK: Combining
	
	func previewCombine() {
		let selectedIndexPaths = tableView.selectedIndexPaths.sorted()
		guard
			let foldersViewModel = viewModel as? FoldersViewModel,
			viewModelBeforeCombining == nil, // Prevents you from using the “Combine” button multiple times quickly without dealing with the dialog first. This pattern is similar to checking `didAlreadyCommitOrganize` for “Save (Preview of Organized Albums)”. You must reset `viewModelBeforeCombining = nil` during both reverting and committing.
			let targetIndexPath = selectedIndexPaths.first
		else { return }
		
		viewModelBeforeCombining = foldersViewModel
		
		// Create a child context previewing the changes.
		let previewContext = NSManagedObjectContext(.mainQueue)
		previewContext.parent = viewModel.context
		let combined = previewContext.createFolder(
			byCombiningCollectionsWithInOrder: {
				let selected = selectedIndexPaths.map {
					foldersViewModel.folderNonNil(at: $0)
				}
				return selected.map { $0.objectID }
			}(),
			index: Int64(viewModel.itemIndex(forRow: targetIndexPath.row))
		)
		try! previewContext.obtainPermanentIDs(for: [combined]) // So that we don’t unnecessarily remove and reinsert the row later.
		
		// Apply the preview context to this `FoldersTVC`.
		let previewViewModel = FoldersViewModel(
			context: previewContext,
			prerowsInEachSection: []
		)
		Task {
			await tableView.performBatchUpdates__async {
				self.tableView.scrollToRow(
					at: targetIndexPath,
					at: .none,
					animated: true)
			}
			
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(
				previewViewModel,
				thenSelecting: [targetIndexPath]
			) else { return }
			
			// Prepare an Albums view to present modally.
			let libraryNC = LibraryNC(rootStoryboardName: "AlbumsTVC")
			libraryNC.presentationController!.delegate = self // In case the user dismisses the sheet by swiping it
			presented_previewing_Combine_IndexPaths = selectedIndexPaths
			
			// Configure the `AlbumsTVC`.
			let albumsTVC = libraryNC.viewControllers.first as! AlbumsTVC
			albumsTVC.viewModel = AlbumsViewModel(
				context: previewContext,
				parentFolder: .exists(combined),
				prerowsInEachSection: []
			)
			albumsTVC.is_previewing_combine_with_album_count = combined.contents?.count ?? 0
			albumsTVC.cancel_combine_action = UIAction { [weak self] _ in
				self?.dismiss(animated: true, completion: {
					self?.revertCombine(thenSelect: selectedIndexPaths)
				})
			}
			albumsTVC.save_combine_action = UIAction { [weak self] _ in
				self?.dismiss(animated: true, completion: {
					self?.commitCombine(into: targetIndexPath)
				})
			}
			
			present(libraryNC, animated: true)
		}
	}
	
	func revertCombine(
		thenSelect originalSelectedIndexPaths: [IndexPath]
	) {
		guard let originalViewModel = viewModelBeforeCombining else { return }
		
		viewModelBeforeCombining = nil
		
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(
				originalViewModel,
				thenSelecting: Set(originalSelectedIndexPaths)
			)
		}
	}
	
	private func commitCombine(
		into indexPathOfCombined: IndexPath
	) {
		let foldersViewModel = viewModel as! FoldersViewModel
		
		viewModelBeforeCombining = nil
		
		viewModel.context.tryToSave()
		viewModel.context.parent!.tryToSave() // TO DO: Crashes
		
		let newViewModel = FoldersViewModel(
			context: viewModel.context.parent!,
			prerowsInEachSection: foldersViewModel.prerowsInEachSection)
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(
				newViewModel,
				thenSelecting: [indexPathOfCombined]
			)
		}
	}
}
