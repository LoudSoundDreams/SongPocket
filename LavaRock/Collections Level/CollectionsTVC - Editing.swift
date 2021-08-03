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
//		super.setEditing(
//			editing,
//			animated: animated)
//
//		refreshVoiceControlNamesForAllCells()
//	}
	
//	private func refreshVoiceControlNamesForAllCells() {
//		indexPaths(forIndexOfSectionOfLibraryItems: 0).forEach {
//			guard let cell = tableView.cellForRow(at: $0) else { return }
//			
//			refreshVoiceControlNames(for: cell)
//		}
//	}
	
	// MARK: - Allowing
	
	final func allowsCombine() -> Bool {
		guard !sectionOfLibraryItems.isEmpty() else {
			return false
		}
		
		return tableView.indexPathsForSelectedRowsNonNil.count >= 2
	}
	
	// MARK: - Renaming
	
	// Match presentDialogToMakeNewCollection and presentDialogToCombineCollections.
	final func presentDialogToRenameCollection(at indexPath: IndexPath) {
		guard let collection = libraryItem(for: indexPath) as? Collection else { return }
		
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
				withProposedTitle: proposedTitle,
				at: indexPath,
				thenSelectRow: wasRowSelectedBeforeRenaming)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		present(dialog, animated: true)
	}
	
	private func rename(
		_ renamedCollection: Collection,
		withProposedTitle proposedTitle: String?,
		at indexPath: IndexPath,
		thenSelectRow: Bool
	) {
		let oldTitle = renamedCollection.title
		if let newTitle = Collection.validatedTitleOptional(from: proposedTitle) {
			renamedCollection.title = newTitle
		}
		let didChangeTitle = renamedCollection.title != oldTitle
		
		managedObjectContext.tryToSave()
		
		if didChangeTitle {
			tableView.reloadRows(at: [indexPath], with: .fade)
		}
		if thenSelectRow {
			tableView.selectRow(
				at: indexPath,
				animated: false,
				scrollPosition: .none)
		}
	}
	
	// MARK: - Combining
	
	final func previewCombineSelectedCollectionsAndPresentDialog() {
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil.sorted()
		guard
			allowsCombine(),
			sectionOfCollectionsBeforeCombining == nil, // Prevents you from using the "Combine" button multiple times quickly without dealing with the dialog first. This pattern is similar to checking `didAlreadyMakeNewCollection` when we tap "New Collection", and `didAlreadyCommitMoveAlbums` for "Move (Albums) Here".
			// You must reset sectionOfCollectionsBeforeCombining = nil during both reverting and committing.
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
		// Save the existing SectionOfCollectionsOrAlbums for if we need to revert, and to prevent ourselves from starting another preview while we're already previewing.
		sectionOfCollectionsBeforeCombining = sectionOfLibraryItems // SIDE EFFECT
		
		// Create the combined Collection.
		let selectedLibraryItems = selectedIndexPaths.map { libraryItem(for: $0) }
		guard let selectedCollections = selectedLibraryItems as? [Collection] else { return }
		let indexOfCombinedCollection = indexOfLibraryItem(
			for: indexPathOfCombinedCollection)
		let combinedCollection = Collection.makeByCombining_withoutDeletingOrReindexing( // SIDE EFFECT
			selectedCollections,
			title: LocalizedString.combinedCollectionDefaultTitle,
			index: Int64(indexOfCombinedCollection),
			via: managedObjectContext)
		// WARNING: We still need to delete empty Collections and reindex all Collections.
		// Do that later, when we commit, because if we revert, we have to restore the original Collections, and Core Data warns you if you mutate managed objects after deleting them.
		try? managedObjectContext.obtainPermanentIDs( // SIDE EFFECT
			for: [combinedCollection]) // So that the "now playing" indicator can appear on the combined Collection.
		
		// Make a new data source.
		var newItems = sectionOfLibraryItems.items
		let indexesOfSelectedCollections = selectedIndexPaths.map {
			indexOfLibraryItem(for: $0)
		}
		indexesOfSelectedCollections.reversed().forEach { newItems.remove(at: $0) }
		newItems.insert(combinedCollection, at: indexOfCombinedCollection)
		
		// Update the data source and table view.
		setItemsAndRefreshToMatch(
			newItems: newItems, // SIDE EFFECT: Reindexes each Collection's `index` attribute
			indexesOfNewItemsToSelect: [indexOfCombinedCollection]
		)
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
				withProposedTitle: proposedTitle)
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
			var copyOfOriginalSection = sectionOfCollectionsBeforeCombining,
			let originalItems = sectionOfCollectionsBeforeCombining?.items
		else { return } //
		sectionOfCollectionsBeforeCombining = nil // SIDE EFFECT
		
		// Revert sectionOfLibraryItems to sectionOfCollectionsBeforeCombining, but give it the currently onscreen `items`, so that we can animate the change.
		copyOfOriginalSection.setItems(sectionOfLibraryItems.items) // To match the currently onscreen items. Should cause no side effects.
		managedObjectContext.rollback() // SIDE EFFECT
		sectionOfLibraryItems = copyOfOriginalSection // SIDE EFFECT
		
		let indexesOfOriginalSelectedCollections = originalSelectedIndexPaths.map {
			indexOfLibraryItem(for: $0)
		}
		setItemsAndRefreshToMatch(
			newItems: originalItems, // SIDE EFFECT
			indexesOfNewItemsToSelect: indexesOfOriginalSelectedCollections
		) {
			completion?()
		}
	}
	
	private func commitCombineCollections(
		into indexPathOfCombinedCollection: IndexPath,
		withProposedTitle proposedTitle: String?
	) {
		guard let combinedCollection = libraryItem(for: indexPathOfCombinedCollection) as? Collection else { return }
		
		let oldTitle = combinedCollection.title
		if let newTitle = Collection.validatedTitleOptional(from: proposedTitle) {
			combinedCollection.title = newTitle
		}
		let didChangeTitle = combinedCollection.title != oldTitle
		
		Collection.deleteAllEmpty(via: managedObjectContext)
		
		managedObjectContext.tryToSave()
		
		sectionOfCollectionsBeforeCombining = nil // SIDE EFFECT
		
		if didChangeTitle {
			tableView.reloadRows(at: [indexPathOfCombinedCollection], with: .fade)
		}
		tableView.selectRow(
			at: indexPathOfCombinedCollection,
			animated: false,
			scrollPosition: .none)
	}
	
}
