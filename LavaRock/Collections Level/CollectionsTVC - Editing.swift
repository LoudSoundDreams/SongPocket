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
	
	// Match presentDialogToMakeNewCollection.
	final func presentDialogToRenameCollection(at indexPath: IndexPath) {
		guard let collection = libraryItem(for: indexPath) as? Collection else { return }
		
		let wasRowSelectedBeforeRenaming = tableView.indexPathsForSelectedRowsNonNil.contains(indexPath)
		
		let dialog = UIAlertController(
			title: LocalizedString.renameCollection,
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
		_ collection: Collection,
		withProposedTitle proposedTitle: String?,
		at indexPath: IndexPath,
		thenSelectRow: Bool
	) {
		if let newTitle = Collection.titleNotEmptyAndNotTooLong(from: proposedTitle) {
			collection.title = newTitle
		}
		managedObjectContext.tryToSave()
		
		tableView.reloadRows(at: [indexPath], with: .fade)
		if thenSelectRow {
			tableView.selectRow(
				at: indexPath,
				animated: false,
				scrollPosition: .none)
		}
	}
	
	// MARK: - Combining
	
	@objc final func previewCombineSelectedCollectionsAndPresentDialog() {
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil.sorted()
		guard
			allowsCombine(),
			sectionOfCollectionsBeforeCombining == nil, // Without this, if you tap the "Combine" button multiple times quickly, we'll try to combine the already-combined Collection.
			// This pattern is similar to checking `didAlreadyMakeNewCollection` when we tap "New Collection", and `didAlreadyCommitMoveAlbums` for "Move (Albums) Here".
			let indexPathOfCombinedCollection = selectedIndexPaths.first
		else { return }
		
		previewCombineCollections(
			from: selectedIndexPaths,
			into: indexPathOfCombinedCollection
		) {
			self.presentDialogToCombineCollections(
				from: selectedIndexPaths,
				into: indexPathOfCombinedCollection)
		}
	}
	
	private func previewCombineCollections(
		from selectedIndexPaths: [IndexPath],
		into indexPathOfCombinedCollection: IndexPath,
		completion: (() -> ())?
	) {
		// Save the existing SectionOfCollectionsOrAlbums for if we need to revert.
		sectionOfCollectionsBeforeCombining = sectionOfLibraryItems // SIDE EFFECT
		
		// Create the combined Collection.
		let selectedLibraryItems = selectedIndexPaths.map { libraryItem(for: $0) }
		guard let selectedCollections = selectedLibraryItems as? [Collection] else { return }
		let indexOfCombinedCollection = indexOfLibraryItem(
			for: indexPathOfCombinedCollection)
		let combinedCollection = Collection.makeByCombining_withoutDeletingOrReindexing( // SIDE EFFECT
			selectedCollections,
			title: LocalizedString.defaultTitleForCombinedCollection,
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
		indexesOfSelectedCollections.reversed().forEach {
			newItems.remove(at: $0)
		}
		newItems.insert(combinedCollection, at: indexOfCombinedCollection)
		
		// Update the data source and table view.
		setItemsAndRefreshTableView(
			newItems: newItems, // SIDE EFFECT: Reindexes each Collection's `index` attribute
			indexesOfNewItemsToSelect: [indexOfCombinedCollection]
		) {
			completion?()
		}
		// Don't call didChangeRowsOrSelectedRows here; otherwise, you'll enable the "Sort" button for the new combined Collection, which users can tap before we present the dialog, if they're fast.
		// BUG: If the uncombined Collections were contiguous to begin with, users can tap "Sort" before we present the dialog, and that puts our app into an incoherent state.
	}
	
	private func presentDialogToCombineCollections(
		from originalSelectedIndexPaths: [IndexPath],
		into indexPathOfCombinedCollection: IndexPath
	) {
		let dialog = UIAlertController(
			title: "Combine Collections", // TO DO: Localize
			message: nil,
			preferredStyle: .alert)
		dialog.addTextFieldForCollectionTitle(defaultTitle: nil)
		
		let cancelAction = UIAlertAction.cancel { _ in
			self.revertCombineCollections(
				from: originalSelectedIndexPaths,
				completion: nil)
		}
		let saveAction = UIAlertAction(
			title: LocalizedString.save,
			style: .default
		) { _ in
			let proposedTitle = dialog.textFields?[0].text
			self.commitCombineCollection(
				into: indexPathOfCombinedCollection,
				withProposedTitle: proposedTitle)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		present(dialog, animated: true)
	}
	
	final func revertCombineCollections(
		from originalSelectedIndexPaths: [IndexPath],
		completion: (() -> ())?
	) {
		guard
			var copyOfOriginalSection = sectionOfCollectionsBeforeCombining,
			let originalItems = sectionOfCollectionsBeforeCombining?.items
		else { return }
		sectionOfCollectionsBeforeCombining = nil // SIDE EFFECT
		
		// Revert sectionOfLibraryItems to sectionOfCollectionsBeforeCombining, but give it the currently onscreen `items`, so that we can animate the change.
		copyOfOriginalSection.setItems(sectionOfLibraryItems.items) // To match the currently onscreen items. Should cause no side effects.
		managedObjectContext.rollback() // SIDE EFFECT
		sectionOfLibraryItems = copyOfOriginalSection // SIDE EFFECT
		
		let indexesOfOriginalSelectedCollections = originalSelectedIndexPaths.map {
			indexOfLibraryItem(for: $0)
		}
		setItemsAndRefreshTableView(
			newItems: originalItems, // SIDE EFFECT
			indexesOfNewItemsToSelect: indexesOfOriginalSelectedCollections
		) {
			completion?()
		}
		didChangeRowsOrSelectedRows() // Trigger refreshEditingButtons early, so that we disable the "Sort" button for non-contiguous original Collections.
	}
	
	private func commitCombineCollection(
		into indexPathOfCombinedCollection: IndexPath,
		withProposedTitle proposedTitle: String?
	) {
		guard let collection = libraryItem(for: indexPathOfCombinedCollection) as? Collection else { return }
		if let newTitle = Collection.titleNotEmptyAndNotTooLong(from: proposedTitle) {
			collection.title = newTitle
		}
		
		Collection.deleteAllEmpty(via: managedObjectContext)
		managedObjectContext.tryToSave()
		
		sectionOfCollectionsBeforeCombining = nil // SIDE EFFECT
		
		tableView.reloadRows(at: [indexPathOfCombinedCollection], with: .fade)
		tableView.selectRow(
			at: indexPathOfCombinedCollection,
			animated: false,
			scrollPosition: .none)
	}
	
}
