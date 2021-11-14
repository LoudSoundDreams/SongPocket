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
	
	// Match presentDialogToMakeNewCollection and presentDialogToCombineCollections.
	final func presentDialogToRenameCollection(at indexPath: IndexPath) {
		guard let collection = viewModel.item(at: indexPath) as? Collection else { return }
		
		let wasRowSelectedBeforeRenaming = tableView.indexPathsForSelectedRowsNonNil.contains(indexPath)
		
		let dialog = UIAlertController(
			title: FeatureFlag.multicollection ? LocalizedString.renameSectionAlertTitle : LocalizedString.renameCollectionAlertTitle,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextFieldForCollectionTitle(defaultTitle: collection.title)
		
		let cancelAction = UIAlertAction.cancel(handler: nil)
		let saveAction = UIAlertAction(
			title: LocalizedString.save,
			style: .default
		) { _ in
			let proposedTitle = dialog.textFields?.first?.text
			self.rename(
				collection,
				proposedTitle: proposedTitle,
				at: indexPath,
				thenSelectRow: wasRowSelectedBeforeRenaming)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		present(dialog, animated: true)
	}
	
	private func rename(
		_ collection: Collection,
		proposedTitle: String?,
		at indexPath: IndexPath,
		thenSelectRow: Bool
	) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		let didChangeTitle = collectionsViewModel.rename(
			at: indexPath,
			proposedTitle: proposedTitle)
		
		collectionsViewModel.context.tryToSave()
		
		if didChangeTitle {
			tableView.reloadRows(at: [indexPath], with: .fade)
		}
		if thenSelectRow {
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		}
	}
	
	// MARK: - Combining
	
	final func previewCombineSelectedCollectionsAndPresentDialog() {
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil.sorted()
		guard
			!isPreviewingCombineCollections, // Prevents you from using the "Combine" button multiple times quickly without dealing with the dialog first. This pattern is similar to checking `didAlreadyMakeNewCollection` when we tap "New Collection", and `didAlreadyCommitMoveAlbums` for "Move (Albums) Here".
			// You must reset groupOfCollectionsBeforeCombining = nil during both reverting and committing.
			let indexPathOfCombinedCollection = selectedIndexPaths.first
		else { return }
		
		previewCombineCollections(
			from: selectedIndexPaths,
			into: indexPathOfCombinedCollection)
		presentDialogToCombineCollections(
			from: selectedIndexPaths,
			into: indexPathOfCombinedCollection)
	}
	
	private func previewCombineCollections(
		from selectedIndexPaths: [IndexPath],
		into indexPathOfCombinedCollection: IndexPath
	) {
		/*
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return } // TO DO: Don't continue to presentDialogToCombineCollections if this fails.
		
		// Save the existing GroupOfCollectionsOrAlbums for if we need to revert, and to prevent ourselves from starting another preview while we're already previewing.
		groupOfCollectionsBeforeCombining = collectionsViewModel.group // SIDE EFFECT
		
		// SIDE EFFECTS:
		// - Creates Collection
		// - Modifies Albums
		let newItems = collectionsViewModel.itemsAfterCombiningCollections(
			from: selectedIndexPaths,
			into: indexPathOfCombinedCollection)
		
		setItemsAndMoveRows(
			newItems: newItems, // SIDE EFFECT: Reindexes each Collection's `index` attribute
//			thenSelect: [indexPathOfCombinedCollection],
			section: indexPathOfCombinedCollection.section)
		
		// TO DO: Deselect rows and refresh editing buttons?
		
		// I would prefer waiting for the table view to complete its animation before presenting the dialog. However, during that animation, you can tap "Move to Top" or "Move to Bottom", or "Sort" if the uncombined Collections were contiguous, which causes us to not present the dialog, which puts our app into an incoherent state.
		 // Whatever you do, use the same timing for presenting the "New Collection" dialog.
		 */
	}
	
	// Match presentDialogToRenameCollection and presentDialogToMakeNewCollection.
	private func presentDialogToCombineCollections(
		from originalSelectedIndexPaths: [IndexPath],
		into indexPathOfCombinedCollection: IndexPath
	) {
		let dialog = UIAlertController(
			title: LocalizedString.combineSectionsAlertTitle,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextFieldForCollectionTitle(defaultTitle: nil)
		
		let cancelAction = UIAlertAction.cancel { _ in
			self.revertCombineCollections(
				thenSelectRowsAt: originalSelectedIndexPaths)
		}
		let saveAction = UIAlertAction(
			title: LocalizedString.save,
			style: .default
		) { _ in
			let proposedTitle = dialog.textFields?.first?.text
			self.commitCombineCollections(
				into: indexPathOfCombinedCollection,
				proposedTitle: proposedTitle)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		present(dialog, animated: true)
	}
	
	final func revertCombineCollections(
		thenSelectRowsAt originalSelectedIndexPaths: [IndexPath],
		completion: (() -> Void)? = nil
	) {
		/*
		guard
			var copyOfOriginalGroup = groupOfCollectionsBeforeCombining,
			let originalItems = groupOfCollectionsBeforeCombining?.items,
			let onscreenItems = (viewModel as? CollectionsViewModel)?.group.items
		else { return } //
		groupOfCollectionsBeforeCombining = nil // SIDE EFFECT
		
		let indexOfGroup = CollectionsViewModel.indexOfOnlyGroup
		
		// Revert sectionOfLibraryItems to groupOfCollectionsBeforeCombining, but give it the currently onscreen `items`, so that we can animate the change.
		copyOfOriginalGroup.setItems(onscreenItems) // Should cause no side effects.
		viewModel.context.rollback() // SIDE EFFECT
		viewModel.groups[indexOfGroup] = copyOfOriginalGroup // SIDE EFFECT
		
		setItemsAndMoveRows(
			newItems: originalItems, // SIDE EFFECT
//			thenSelect: originalSelectedIndexPaths,
			section: CollectionsViewModel.numberOfSectionsAboveLibraryItems + CollectionsViewModel.indexOfOnlyGroup
		) {
			completion?()
		}
		
		// TO DO: Deselect rows and refresh editing buttons?
		*/
	}
	
	private func commitCombineCollections(
		into indexPathOfCombinedCollection: IndexPath,
		proposedTitle: String?
	) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		let didChangeTitle = collectionsViewModel.rename(
			at: indexPathOfCombinedCollection,
			proposedTitle: proposedTitle)
		
		Collection.deleteAllEmpty(context: collectionsViewModel.context) // SIDE EFFECT
		
		collectionsViewModel.context.tryToSave()
		
		groupOfCollectionsBeforeCombining = nil // SIDE EFFECT
		
		if didChangeTitle {
			tableView.reloadRows(at: [indexPathOfCombinedCollection], with: .fade)
		}
		tableView.selectRow(at: indexPathOfCombinedCollection, animated: false, scrollPosition: .none)
	}
	
}
