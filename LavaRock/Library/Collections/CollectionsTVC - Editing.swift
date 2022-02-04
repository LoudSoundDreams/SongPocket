//
//  CollectionsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension CollectionsTVC: UITextFieldDelegate {
	final func textFieldDidBeginEditing(_ textField: UITextField) {
		textField.selectAll(nil) // As of iOS 15.3 developer beta 1, the selection works but the highlight doesn’t appear if `textField.text` is long.
	}
}

extension CollectionsTVC {
	// MARK: Renaming
	
	final func promptRename(at indexPath: IndexPath) {
		guard let collection = viewModel.itemNonNil(at: indexPath) as? Collection else { return }
		
		let rowWasSelectedBeforeRenaming = tableView.indexPathsForSelectedRowsNonNil.contains(indexPath)
		
		let dialog = UIAlertController.forEditingCollectionTitle(
			alertTitle: Enabling.multicollection
			? LocalizedString.renameSectionAlertTitle
			: LocalizedString.renameCollectionAlertTitle,
			textFieldText: collection.title,
			textFieldDelegate: self,
			cancelHandler: nil,
			saveHandler: { textFieldText in
				self.commitRename(
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
		
		if didChangeTitle {
			tableView.reloadRows(at: [indexPath], with: .fade)
		}
		if shouldSelectRow {
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		}
	}
	
	// MARK: Combining
	
	private static func smartCollectionTitle(
		combining collections: [Collection]
	) -> String? {
		let titles = collections.compactMap { $0.title }
		guard let firstTitle = titles.first else {
			return nil
		}
		let restOfTitles = titles.dropFirst()
		
		// Check whether the titles of the `Collection`s we’re combining are all identical.
		if restOfTitles.allSatisfy({ $0 == firstTitle }) {
			return firstTitle
		}
		
		// Otherwise, give up.
		return nil
	}
	
	final func previewCombineAndPrompt() {
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil.sorted()
		guard
			let collectionsViewModel = viewModel as? CollectionsViewModel,
			viewModelBeforeCombining == nil, // Prevents you from using the “Combine” button multiple times quickly without dealing with the dialog first. This pattern is similar to checking `didAlreadyCreate` when we tap “New Collection”, `didAlreadyCommitMove` for “Move (Albums) Here”, and `didAlreadyCommitOrganize` for “Save (Preview of Organized Albums)”. You must reset `viewModelBeforeCombining = nil` during both reverting and committing.
			let indexPathOfCombined = selectedIndexPaths.first
		else { return }
		
		viewModelBeforeCombining = collectionsViewModel
		
		let selectedCollections = selectedIndexPaths.map { collectionsViewModel.collectionNonNil(at: $0) }
		let smartTitle = Self.smartCollectionTitle(combining: selectedCollections)
		
		let title = smartTitle ?? (
			Enabling.multicollection
			? LocalizedString.combinedSectionDefaultTitle
			: LocalizedString.combinedCollectionDefaultTitle)
		let newViewModel = collectionsViewModel.updatedAfterCombining_inNewChildContext(
			fromInOrder: selectedCollections,
			into: indexPathOfCombined,
			title: title)
		Task {
			let _ = await tableView.performBatchUpdates_async {
				self.tableView.scrollToRow(
					at: indexPathOfCombined,
					at: .none,
					animated: true)
			}
			
			guard await setViewModelAndMoveRowsAndShouldContinue(
				newViewModel,
				thenSelecting: [indexPathOfCombined])
			else { return }
			
			let dialog = UIAlertController.forEditingCollectionTitle(
				alertTitle: Enabling.multicollection
				? LocalizedString.combineSectionsAlertTitle
				: LocalizedString.combineCollectionsAlertTitle,
				textFieldText: smartTitle,
				textFieldDelegate: self,
				cancelHandler: {
					self.revertCombine(thenSelect: selectedIndexPaths)
				},
				saveHandler: { textFieldText in
					self.commitCombine(
						into: indexPathOfCombined,
						proposedTitle: textFieldText)
				})
			present(dialog, animated: true)
		}
	}
	
	final func revertCombine(
		thenSelect originalSelectedIndexPaths: [IndexPath]
	) {
		let originalViewModel = viewModelBeforeCombining!
		
		viewModelBeforeCombining = nil
		
		Task {
			let _ = await setViewModelAndMoveRowsAndShouldContinue(
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
		let toReload = didChangeTitle ? [indexPathOfCombined] : []
		Task {
			let _ = await setViewModelAndMoveRowsAndShouldContinue(
				firstReloading: toReload,
				newViewModel,
				thenSelecting: [indexPathOfCombined])
		}
	}
}
