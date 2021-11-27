//
//  CollectionsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// MARK: - Renaming
	
	final func confirmRename(at indexPath: IndexPath) {
		guard let collection = viewModel.itemNonNil(at: indexPath) as? Collection else { return }
		
		let rowWasSelectedBeforeRenaming = tableView.indexPathsForSelectedRowsNonNil.contains(indexPath)
		
		let dialog = UIAlertController.forEditingCollectionTitle(
			alertTitle: FeatureFlag.multicollection ? LocalizedString.renameSectionAlertTitle : LocalizedString.renameCollectionAlertTitle,
			textFieldText: collection.title,
			cancelHandler: nil,
			saveHandler: { textFieldText in
				self.rename(
					at: indexPath,
					proposedTitle: textFieldText,
					andSelectRowIf: rowWasSelectedBeforeRenaming)
			}
		)
		present(dialog, animated: true)
	}
	
	private func rename(
		at indexPath: IndexPath,
		proposedTitle: String?,
		andSelectRowIf shouldSelectRow: Bool
	) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		let didRename = collectionsViewModel.rename(
			at: indexPath,
			proposedTitle: proposedTitle)
		
		collectionsViewModel.context.tryToSave()
		
		if didRename {
			tableView.reloadRows(at: [indexPath], with: .fade)
		}
		if shouldSelectRow {
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		}
	}
	
	// MARK: - Combining
	
	final func combineAndConfirm() {
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil.sorted()
		guard
			let collectionsViewModel = viewModel as? CollectionsViewModel,
			viewModelBeforeCombining == nil, // Prevents you from using the "Combine" button multiple times quickly without dealing with the dialog first. This pattern is similar to checking `didAlreadyCreateCollection` when we tap "New Collection", and `didAlreadyCommitMoveAlbums` for "Move (Albums) Here".
			// You must reset `viewModelBeforeCombining = nil` during both reverting and committing.
			let indexPathOfCombined = selectedIndexPaths.first
		else { return }
		
		let selectedCollections = selectedIndexPaths.map {
			collectionsViewModel.itemNonNil(at: $0) as! Collection
		}
		let smartTitle = collectionsViewModel.smartTitle(combining: selectedCollections)
		combine(
			fromCollectionsInOrder: selectedCollections,
			into: indexPathOfCombined,
			smartTitle: smartTitle)
		// I would prefer waiting for the table view to complete its animation before presenting the dialog. However, during the table view animation, you can tap other editing buttons, which can put our app into an incoherent state.
		// Whatever the case, creating a new `Collection` should use the same animation timing.
		confirmCombine(
			fromIndexPathsInOrder: selectedIndexPaths,
			into: indexPathOfCombined,
			smartTitle: smartTitle)
	}
	
	private func combine(
		fromCollectionsInOrder collections: [Collection],
		into indexPathOfCombined: IndexPath,
		smartTitle: String?
	) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		viewModelBeforeCombining = collectionsViewModel
		
		let title = smartTitle ?? (FeatureFlag.multicollection ? LocalizedString.combinedSectionDefaultTitle : LocalizedString.combinedCollectionDefaultTitle)
		let newViewModel = collectionsViewModel.updatedAfterCombining_inNewChildContext(
			fromCollectionsInOrder: collections,
			into: indexPathOfCombined,
			title: title)
		setViewModelAndMoveRows(newViewModel)
	}
	
	private func confirmCombine(
		fromIndexPathsInOrder originalSelectedIndexPaths: [IndexPath],
		into indexPathOfCombined: IndexPath,
		smartTitle: String?
	) {
		let dialog = UIAlertController.forEditingCollectionTitle(
			alertTitle: FeatureFlag.multicollection ? LocalizedString.combineSectionsAlertTitle : LocalizedString.combineCollectionsAlertTitle,
			textFieldText: smartTitle,
			cancelHandler: {
				self.revertCombine(andSelectRowsAt: originalSelectedIndexPaths)
			},
			saveHandler: { textFieldText in
				self.commitCombine(
					into: indexPathOfCombined,
					proposedTitle: textFieldText)
			}
		)
		present(dialog, animated: true)
	}
	
	final func revertCombine(
		andSelectRowsAt originalSelectedIndexPaths: [IndexPath]
	) {
		guard let originalViewModel = viewModelBeforeCombining else { return }
		
		viewModelBeforeCombining = nil
		
		setViewModelAndMoveRows(
			originalViewModel,
			andSelectRowsAt: Set(originalSelectedIndexPaths))
	}
	
	private func commitCombine(
		into indexPathOfCombined: IndexPath,
		proposedTitle: String?
	) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		viewModelBeforeCombining = nil
		
		let didRename = collectionsViewModel.rename(
			at: indexPathOfCombined,
			proposedTitle: proposedTitle)
		
		collectionsViewModel.context.tryToSave()
		collectionsViewModel.context.parent!.tryToSave()
		
		let newViewModel = CollectionsViewModel(context: collectionsViewModel.context.parent!)
		setViewModelAndMoveRows(newViewModel)
		
		if didRename {
			tableView.reloadRows(at: [indexPathOfCombined], with: .fade)
		}
		tableView.selectRow(at: indexPathOfCombined, animated: false, scrollPosition: .none)
	}
	
}
