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
	// MARK: Renaming
	
	func promptRename(at indexPath: IndexPath) {
		guard let collection = viewModel.itemNonNil(at: indexPath) as? Collection else { return }
		
		let rowWasSelectedBeforeRenaming = tableView.selectedIndexPaths.contains(indexPath)
		
		let dialog = UIAlertController.forEditingCollectionTitle(
			alertTitle: LRString.renameFolderAlertTitle,
			textFieldText: collection.title,
			textFieldDelegate: self,
			cancelHandler: nil,
			saveHandler: { [weak self] textFieldText in
				self?.commitRename(
					at: indexPath,
					proposedTitle: textFieldText,
					thenSelectIf: rowWasSelectedBeforeRenaming)
			})
		present(dialog, animated: true)
	}
	
	private func commitRename(
		at indexPath: IndexPath,
		proposedTitle: String?,
		thenSelectIf shouldSelectRow: Bool
	) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		let didChangeTitle = collectionsViewModel.renameAndReturnDidChangeTitle(
			at: indexPath,
			proposedTitle: proposedTitle)
		
		viewModel.context.tryToSave()
		
		Task {
			if didChangeTitle {
				// See corresponding comment in `commitCombine`.
				await tableView.performBatchUpdates__async {
					self.tableView.reloadRows(at: [indexPath], with: .fade)
				} runningBeforeContinuation: {
					if shouldSelectRow {
						self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
					}
				}
			}
			
			setEditing(false, animated: true)
		}
	}
	
	// MARK: Combining
	
	private static func suggestedCollectionTitle(
		combining collections: [Collection]
	) -> String? {
		let titles = collections.compactMap { $0.title }
		guard let firstTitle = titles.first else {
			return nil
		}
		let restOfTitles = titles.dropFirst()
		
		// If all the `Collection`s we’re combining have identical titles …
		if restOfTitles.allSatisfy({ $0 == firstTitle }) {
			return firstTitle
		}
		
		// Otherwise, give up.
		return nil
	}
	
	func previewCombine() {
		let selectedIndexPaths = tableView.selectedIndexPaths.sorted()
		guard
			let collectionsViewModel = viewModel as? CollectionsViewModel,
			viewModelBeforeCombining == nil, // Prevents you from using the “Combine” button multiple times quickly without dealing with the dialog first. This pattern is similar to checking `didAlreadyCreate` when we tap “New Collection”, `didAlreadyCommitMove` for “Move (Albums) Here”, and `didAlreadyCommitOrganize` for “Save (Preview of Organized Albums)”. You must reset `viewModelBeforeCombining = nil` during both reverting and committing.
			let targetIndexPath = selectedIndexPaths.first
		else { return }
		
		viewModelBeforeCombining = collectionsViewModel
		
		let selectedCollections = selectedIndexPaths.map { collectionsViewModel.collectionNonNil(at: $0) }
		let titleForCombinedCollection = Self.suggestedCollectionTitle(combining: selectedCollections)
		?? LRString.combinedFolderDefaultTitle
		
		// Create a child context previewing the changes.
		let previewContext = NSManagedObjectContext(.mainQueue)
		previewContext.parent = viewModel.context
		let combinedCollection = previewContext.createCollection(
			byCombiningCollectionsWithInOrder: selectedCollections.map { $0.objectID },
			title: titleForCombinedCollection,
			index: Int64(viewModel.itemIndex(forRow: targetIndexPath.row))
		)
		try! previewContext.obtainPermanentIDs(for: [combinedCollection]) // So that we don’t unnecessarily remove and reinsert the row later.
		
		// Apply the preview context to this `CollectionsTVC`.
		let previewViewModel = CollectionsViewModel(
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
			
			let dialog = UIAlertController.forEditingCollectionTitle(
				alertTitle: LRString.combineFoldersAlertTitle,
				textFieldText: titleForCombinedCollection,
				textFieldDelegate: self,
				cancelHandler: { [weak self] in
					self?.revertCombine(thenSelect: selectedIndexPaths)
				},
				saveHandler: { [weak self] textFieldText in
					self?.commitCombine(
						into: targetIndexPath,
						proposedTitle: textFieldText)
				})
			present(dialog, animated: true)
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
				thenSelecting: Set(originalSelectedIndexPaths))
		}
	}
	
	private func commitCombine(
		into indexPathOfCombined: IndexPath,
		proposedTitle: String?
	) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		viewModelBeforeCombining = nil
		
		let didChangeTitle = collectionsViewModel.renameAndReturnDidChangeTitle(
			at: indexPathOfCombined,
			proposedTitle: proposedTitle)
		
		viewModel.context.tryToSave()
		viewModel.context.parent!.tryToSave()
		
		let newViewModel = CollectionsViewModel(
			context: viewModel.context.parent!,
			prerowsInEachSection: collectionsViewModel.prerowsInEachSection)
		Task {
			if didChangeTitle {
				// I would prefer not waiting for the reload animation to complete before exiting editing mode.
				await tableView.performBatchUpdates__async {
					self.tableView.reloadRows(at: [indexPathOfCombined], with: .fade)
				} runningBeforeContinuation: {
					self.tableView.selectRow(at: indexPathOfCombined, animated: false, scrollPosition: .none)
				}
			}
			
			setEditing(false, animated: true)
			
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(
				newViewModel)
		}
	}
}
