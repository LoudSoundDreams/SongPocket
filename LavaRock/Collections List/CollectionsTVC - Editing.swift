//
//  CollectionsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension CollectionsTVC: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		textField.selectAll(nil) // As of iOS 15.3 developer beta 1, the selection works but the highlight doesn’t appear if `textField.text` is long.
	}
}
extension CollectionsTVC {
	
	// MARK: Rename
	
	func promptRename(at indexPath: IndexPath) {
		guard let collection = viewModel.itemNonNil(atRow: indexPath.row) as? Collection else { return }
		
		let dialog = UIAlertController(
			title: LRString.renameCrate,
			message: nil,
			preferredStyle: .alert)
		
		let existingTitle = collection.title
		dialog.addTextField {
			// UITextField
			$0.text = existingTitle
			$0.placeholder = LRString.tilde
			$0.clearButtonMode = .always
			
			// UITextInputTraits
			$0.returnKeyType = .done
			$0.autocapitalizationType = .sentences
			$0.smartQuotesType = .yes
			$0.smartDashesType = .yes
			
			$0.delegate = self
		}
		
		let rowWasSelectedBeforeRenaming = tableView.selectedIndexPaths.contains(indexPath)
		let done = UIAlertAction(title: LRString.done, style: .default) { [weak self] _ in
			self?.commitRename(
				textFieldText: dialog.textFields?.first?.text,
				indexPath: indexPath,
				thenShouldReselect: rowWasSelectedBeforeRenaming
			)
		}
		
		dialog.addAction(UIAlertAction(title: LRString.cancel, style: .cancel))
		dialog.addAction(done)
		dialog.preferredAction = done
		
		present(dialog, animated: true)
	}
	private func commitRename(
		textFieldText: String?,
		indexPath: IndexPath,
		thenShouldReselect: Bool
	) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		let collection = collectionsViewModel.collectionNonNil(atRow: indexPath.row)
		
		let proposedTitle = (textFieldText ?? "").truncated(toMaxLength: 256) // In case the user entered a dangerous amount of text
		if proposedTitle.isEmpty {
			collection.title = LRString.tilde
		} else {
			collection.title = proposedTitle
		}
		
		Task {
			await tableView.performBatchUpdates__async {
				self.tableView.reloadRows(at: [indexPath], with: .fade)
			} runningBeforeContinuation: {
				if thenShouldReselect {
					self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
				}
			}
		}
	}
	
	// MARK: Combine
	
	func previewCombine() {
		let selectedIndexPaths = tableView.selectedIndexPaths.sorted()
		guard
			let collectionsViewModel = viewModel as? CollectionsViewModel,
			viewModelBeforeCombining == nil, // Prevents users from activating the “Combine” button multiple times quickly without dealing with the dialog first. This is analogous to the way we check `hasCreatedNewCollection` and `didAlreadyCommitOrganize`.
			// You must reset `viewModelBeforeCombining = nil` during both reverting and committing.
			let targetIndexPath = selectedIndexPaths.first
		else { return }
		
		viewModelBeforeCombining = collectionsViewModel
		
		// Create a child context previewing the changes.
		let previewContext = NSManagedObjectContext(.mainQueue)
		previewContext.parent = viewModel.context
		let combined = previewContext.combine(
			{
				let selected = selectedIndexPaths.map {
					collectionsViewModel.collectionNonNil(atRow: $0.row)
				}
				return selected.map { $0.objectID }
			}(),
			index: Int64(viewModel.itemIndex(forRow: targetIndexPath.row))
		)
		try! previewContext.obtainPermanentIDs(for: [combined]) // So that we don’t unnecessarily remove and reinsert the row later.
		
		// Apply the preview context in the current view.
		let previewViewModel = CollectionsViewModel(context: previewContext)
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
			let nc = UINavigationController(
				rootViewController: UIStoryboard(name: "AlbumsTVC", bundle: nil)
					.instantiateInitialViewController()!
			)
			nc.presentationController!.delegate = self // In case the user dismisses the sheet by swiping it
			presented_previewing_Combine_IndexPaths = selectedIndexPaths
			
			// Configure the `AlbumsTVC`.
			let albumsTVC = nc.viewControllers.first as! AlbumsTVC
			albumsTVC.viewModel = AlbumsViewModel(
				collection: combined,
				context: previewContext)
			albumsTVC.is_previewing_combine_with_album_count = combined.contents?.count ?? 0
			albumsTVC.cancel_combine_action = UIAction { [weak self] _ in
				self?.dismiss(animated: true, completion: {
					self?.revertCombine(thenSelect: selectedIndexPaths)
				})
			}
			albumsTVC.save_combine_action = UIAction { [weak self] _ in
				self?.dismiss(animated: true, completion: {
					self?.commitCombine(intoIndexPath: targetIndexPath)
				})
			}
			
			present(nc, animated: true)
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
	
	private func commitCombine(intoIndexPath: IndexPath) {
		viewModelBeforeCombining = nil
		
		viewModel.context.tryToSave()
		viewModel.context.parent!.tryToSave() // TO DO: Crashes
		
		let newViewModel = CollectionsViewModel(context: viewModel.context.parent!)
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(
				newViewModel,
				thenSelecting: [intoIndexPath]
			)
		}
	}
}
