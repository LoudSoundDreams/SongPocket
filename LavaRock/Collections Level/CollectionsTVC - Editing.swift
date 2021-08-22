//
//  CollectionsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
//	override func setEditing(_ editing: Bool, animated: Bool) {
//		super.setEditing(editing, animated: animated)
//
//		let indexOfAllSection = CollectionsSection.all.rawValue
//		let allSection = tableView.indexPathsForRows(
//			inSection: indexOfAllSection,
//			firstRow: 0)
//		tableView.reloadRows(at: allSection, with: .fade) //
//
////		refreshVoiceControlNamesForCollectionCells()
//	}
	
//	private func refreshVoiceControlNamesForCollectionCells() {
//		indexPaths(forIndexOfSectionOfLibraryItems: 0).forEach {
//			guard let cell = tableView.cellForRow(at: $0) else { return }
//			
//			refreshVoiceControlNames(for: cell)
//		}
//	}
	
	// MARK: - Renaming
	
	// Match presentDialogToMakeNewCollection and presentDialogToCombineCollections.
	final func presentDialogToRenameCollection(at indexPath: IndexPath) {
		guard let collection = viewModel.item(at: indexPath) as? Collection else { return }
		
		let wasRowSelectedBeforeRenaming = tableView.indexPathsForSelectedRowsNonNil.contains(indexPath)
		
		let dialog = UIAlertController(
			title: LocalizedString.renameCollectionAlertTitle,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextFieldForCollectionTitle(defaultTitle: collection.title)
		
		let cancelAction = UIAlertAction.cancel(handler: nil)
		let saveAction = UIAlertAction(
			title: LocalizedString.save,
			style: .default
		) { _ in
			let proposedTitle = dialog.textFields?[0].text
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
		
		// Make a new data source.
		let (newItems, didChangeTitle) = collectionsViewModel.itemsAfterRenamingCollection(
			at: indexPath,
			proposedTitle: proposedTitle)
		
		let indexOfCollection = collectionsViewModel.indexOfItemInGroup(forRow: indexPath.row)
		let toReload = didChangeTitle ? [indexOfCollection] : []
		let toSelect = thenSelectRow ? [indexOfCollection] : []
		
		// Update the data source and table view.
		setItemsAndRefresh(
			newItems: newItems,
			indicesOfNewItemsToReload: toReload,
			indicesOfNewItemsToSelect: toSelect,
			section: indexPath.section
		) {
			self.viewModel.context.tryToSave()
		}
	}
	
	// MARK: - Combining
	
	final func isPreviewingCombineCollections() -> Bool {
		return groupOfCollectionsBeforeCombining != nil
	}
	
	final func previewCombineSelectedCollectionsAndPresentDialog() {
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil.sorted()
		guard
			(viewModel as? CollectionsViewModel)?.allowsCombine(selectedIndexPaths: selectedIndexPaths) ?? false,
			!isPreviewingCombineCollections(), // Prevents you from using the "Combine" button multiple times quickly without dealing with the dialog first. This pattern is similar to checking `didAlreadyMakeNewCollection` when we tap "New Collection", and `didAlreadyCommitMoveAlbums` for "Move (Albums) Here".
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
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return } // TO DO: Don't continue to presentDialogToCombineCollections if this fails.
		
		// Save the existing GroupOfCollectionsOrAlbums for if we need to revert, and to prevent ourselves from starting another preview while we're already previewing.
		groupOfCollectionsBeforeCombining = collectionsViewModel.group // SIDE EFFECT
		
		// Make a new data source.
		// SIDE EFFECTS:
		// - Creates Collection
		// - Modifies Albums
		let newItems = collectionsViewModel.itemsAfterCombiningCollections(
			from: selectedIndexPaths,
			into: indexPathOfCombinedCollection)
		
		// Update the data source and table view.
		let indexOfCombinedCollection = collectionsViewModel.indexOfItemInGroup(forRow: indexPathOfCombinedCollection.row)
		setItemsAndRefresh(
			newItems: newItems, // SIDE EFFECT: Reindexes each Collection's `index` attribute
			indicesOfNewItemsToSelect: [indexOfCombinedCollection],
			section: indexPathOfCombinedCollection.section)
		// I would prefer waiting for the table view to complete its animation before presenting the dialog. However, during that animation, you can tap "Move to Top" or "Move to Bottom", or "Sort" if the uncombined Collections were contiguous, which causes us to not present the dialog, which puts our app into an incoherent state.
		// We could hack refreshEditingButtons to disable all the editing buttons during the animation, but that would clearly break separation of concerns.
	}
	
	// Match presentDialogToRenameCollection and presentDialogToMakeNewCollection.
	private func presentDialogToCombineCollections(
		from originalSelectedIndexPaths: [IndexPath],
		into indexPathOfCombinedCollection: IndexPath
	) {
		let dialog = UIAlertController(
			title: LocalizedString.combineCollectionsAlertTitle,
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
			let proposedTitle = dialog.textFields?[0].text
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
		guard
			var copyOfOriginalGroup = groupOfCollectionsBeforeCombining,
			let originalItems = groupOfCollectionsBeforeCombining?.items,
			let onscreenItems = (viewModel as? CollectionsViewModel)?.group.items
		else { return } //
		groupOfCollectionsBeforeCombining = nil // SIDE EFFECT
		
		let indexOfGroup = CollectionsViewModel.indexOfGroup
		
		// Revert sectionOfLibraryItems to groupOfCollectionsBeforeCombining, but give it the currently onscreen `items`, so that we can animate the change.
		copyOfOriginalGroup.setItems(onscreenItems) // Should cause no side effects.
		viewModel.context.rollback() // SIDE EFFECT
		viewModel.groups[indexOfGroup] = copyOfOriginalGroup // SIDE EFFECT
		
		let indicesOfOriginalSelectedCollections = originalSelectedIndexPaths.map {
			viewModel.indexOfItemInGroup(forRow: $0.row)
		}
		setItemsAndRefresh(
			newItems: originalItems, // SIDE EFFECT
			indicesOfNewItemsToSelect: indicesOfOriginalSelectedCollections,
			section: CollectionsViewModel.numberOfSectionsAboveLibraryItems + CollectionsViewModel.indexOfGroup
		) {
			completion?()
		}
	}
	
	private func commitCombineCollections(
		into indexPathOfCombinedCollection: IndexPath,
		proposedTitle: String?
	) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		// Make a new data source.
		let (newItems, didChangeTitle) = collectionsViewModel.itemsAfterRenamingCollection( // SIDE EFFECT
			at: indexPathOfCombinedCollection,
			proposedTitle: proposedTitle)
		
		Collection.deleteAllEmpty(context: viewModel.context) // SIDE EFFECT
		
		groupOfCollectionsBeforeCombining = nil // SIDE EFFECT
		
		let indexOfCollection = collectionsViewModel.indexOfItemInGroup(forRow: indexPathOfCombinedCollection.row)
		let toReload = didChangeTitle ? [indexOfCollection] : []
		let toSelect = [indexOfCollection]
		
		// Update the data source and table view.
		setItemsAndRefresh(
			newItems: newItems,
			indicesOfNewItemsToReload: toReload,
			indicesOfNewItemsToSelect: toSelect,
			section: indexPathOfCombinedCollection.section
		) {
			self.viewModel.context.tryToSave()
		}
	}
	
}
