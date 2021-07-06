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
//		for indexPath in tableView.indexPathsForRows(
//			inSection: 0,
//			firstRow: numberOfRowsAboveLibraryItems)
//		{
//			guard let cell = tableView.cellForRow(at: indexPath) else { continue }
//			
//			refreshVoiceControlNames(for: cell)
//		}
//	}
	
	// MARK: - Allowing
	
	final func allowsCombine() -> Bool {
		guard !sectionOfLibraryItems.items.isEmpty else {
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
		
		tableView.reloadRows(at: [indexPath], with: .fade)
		if thenSelectRow {
			tableView.selectRow(
				at: indexPath,
				animated: false,
				scrollPosition: .none)
		}
	}
	
	// MARK: - Combining
	
	@objc final func presentDialogToCombineSelectedCollections() {
		// When we tap "New Collection" or "Move (Albums) Here", we set `didAlreadyMakeNewCollection` or `didAlreadyCommitMoveAlbums` (respectively) to `true` to prevent unexpected, incorrect sequences of events.
		// However, there's no such problem with the "Combine (Collections)" or "rename (Collection)" buttons.
		
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil.sorted() // Should have at least 2 items, but make this whole thing safe even if it doesn't
		guard let indexPathOfCombinedCollection = selectedIndexPaths.first else { return }
		let defaultTitle = LocalizedString.defaultTitleForCombinedCollection
		
		previewCombineCollections(
			from: selectedIndexPaths,
			into: indexPathOfCombinedCollection,
			withDefaultTitle: defaultTitle
		) {
			self.presentDialogToCombineSelectedCollectionsPart2(
				into: indexPathOfCombinedCollection)
		}
	}
	
	private func previewCombineCollections(
		from selectedIndexPaths: [IndexPath],
		into indexPathOfCombinedCollection: IndexPath,
		withDefaultTitle defaultTitle: String,
		completion: (() -> ())?
	) {
		// Save the existing SectionOfCollectionsOrAlbums for if we need to revert.
		previousSectionOfCollections = sectionOfLibraryItems // SIDE EFFECT
		
		
		
		// Preview the changes using a child managed object context, so that we can cancel without having to revert our changes.
		let childManagedObjectContext = NSManagedObjectContext(
			concurrencyType: .mainQueueConcurrencyType)
		childManagedObjectContext.parent = managedObjectContext
		
		// Change `sectionOfLibraryItems.managedObjectContext`.
		// Instantiate a new SectionOfCollectionsOrAlbums rather than mutating the current one, so that if we change the definition of SectionOfCollectionsOrAlbums, we'll remember to consider the changes here.
		// Also consider how any changes affect revertCombineCollections and commitCombine, below.
		let newSectionOfCollections = SectionOfCollectionsOrAlbums(
			entityName: sectionOfLibraryItems.entityName,
			managedObjectContext: childManagedObjectContext,
			container: sectionOfLibraryItems.container)
		
		// The new instance's `items` must have `objectID`s that match the currently onscreen rows. (That should happen automatically.)
		let previousObjectIDs = sectionOfLibraryItems.items.map { $0.objectID }
		let newObjectIDs = newSectionOfCollections.items.map { $0.objectID }
		precondition(previousObjectIDs == newObjectIDs)
		
		sectionOfLibraryItems = newSectionOfCollections // SIDE EFFECT
		
		
		
		// Create the combined Collection.
		let selectedLibraryItems = selectedIndexPaths.map { libraryItem(for: $0) }
		guard let selectedCollections = selectedLibraryItems as? [Collection] else { return }
		let indexOfCombinedCollection = indexOfLibraryItem(
			for: indexPathOfCombinedCollection)
		let combinedCollection = Collection.makeByCombining_withoutDeletingOrReindexing( // SIDE EFFECT
			selectedCollections,
			title: defaultTitle,
			index: Int64(indexOfCombinedCollection),
			via: sectionOfLibraryItems.managedObjectContext)
		// WARNING: We still need to delete empty Collections and reindex all Collections.
		// Do that later, when we commit, because if we revert, we have to restore the original Collections, and Core Data warns you if you mutate managed objects after deleting them.
		
		
		
		precondition(sectionOfLibraryItems.managedObjectContext.parent != nil)
		// !! the following saves Collections into an incoherent state
		sectionOfLibraryItems.managedObjectContext.tryToSaveSynchronously() // to give the new combined Collection a non-temporary objectID, so that the "now playing" indicator can appear on it
		
		
		
//		try! sectionOfLibraryItems.managedObjectContext.obtainPermanentIDs(for: [combinedCollection])
//		print("")
//		print(combinedCollection.objectID)
//		let collectionForSongInPlayer = PlayerManager.songInPlayer?.container?.container
//		print(String(describing: collectionForSongInPlayer?.title))
//		print(String(describing: collectionForSongInPlayer?.objectID))
//		print("equal? \(combinedCollection.objectID == collectionForSongInPlayer?.objectID)")
		
		
		
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
		setItemsAndRefreshTableView(newItems: newItems) { // SIDE EFFECT
			self.refreshBarButtons() // i really don't want to have to do this manually
			completion?()
		}
	}
	
	private func presentDialogToCombineSelectedCollectionsPart2(
		into indexPathOfCombinedCollection: IndexPath
	) {
		let dialog = UIAlertController(
			title: "Combine Collections", // TO DO: Localize
			message: nil,
			preferredStyle: .alert)
		dialog.addTextFieldForCollectionTitle(defaultTitle: nil)
		
		let cancelAction = UIAlertAction.cancel { _ in
			self.revertCombineCollections(completion: nil)
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
		completion: (() -> ())?
	) {
		guard let originalSectionOfCollections = previousSectionOfCollections else { return }
		
		// Revert sectionOfLibraryItems to previousSectionOfCollections, but give it the currently onscreen `items`, so that we can animate the change.
		var copyOfOriginalSectionOfCollections = originalSectionOfCollections
		
		
		
		precondition(copyOfOriginalSectionOfCollections.managedObjectContext.parent == nil)
		
		
		
		print("")
		print("BEFORE ROLLBACK")
		print("")
		print(Collection.allFetched(via: copyOfOriginalSectionOfCollections.managedObjectContext))
		copyOfOriginalSectionOfCollections.managedObjectContext.rollback() //?
		copyOfOriginalSectionOfCollections.setItems(sectionOfLibraryItems.items)
		sectionOfLibraryItems = copyOfOriginalSectionOfCollections // SIDE EFFECT
		// the above discards child managed object context, which the preview sectionOfLibraryItems referenced
		
		let originalItems = originalSectionOfCollections.items
		previousSectionOfCollections = nil // SIDE EFFECT
		setItemsAndRefreshTableView( // SIDE EFFECT
			newItems: originalItems) {
//			self.refreshBarButtons() // not necessary; i don't ever want to think about this
			completion?()
		}
	}
	
	private func commitCombineCollection(
//		_ collection: Collection,
		into indexPathOfCombinedCollection: IndexPath,
		withProposedTitle proposedTitle: String?
	) {
		
		
		
		// The following should be using the child managed object context on sectionOfLibraryItems.
		guard let collection = libraryItem(for: indexPathOfCombinedCollection) as? Collection else { return }
		if let newTitle = Collection.titleNotEmptyAndNotTooLong(from: proposedTitle) {
			collection.title = newTitle
		}
		
		print("")
		print("BEFORE CLEANUP")
		print("")
		print(Collection.allFetched(via: sectionOfLibraryItems.managedObjectContext))
		Collection.deleteAllEmpty(via: sectionOfLibraryItems.managedObjectContext)
		
		sectionOfLibraryItems.managedObjectContext.tryToSaveSynchronously()
		
		
		
		guard let mainManagedObjectContext = sectionOfLibraryItems.managedObjectContext.parent else {
			fatalError("After the user confirmed to combine Collections, we couldn’t restore the main managed object context.")
		}
		
		// Restore `sectionOfLibraryItems.managedObjectContext`.
		let newSectionOfLibraryItems = SectionOfCollectionsOrAlbums(
			entityName: sectionOfLibraryItems.entityName,
			managedObjectContext: mainManagedObjectContext,
			container: sectionOfLibraryItems.container)
		sectionOfLibraryItems = newSectionOfLibraryItems // SIDE EFFECT
		 
		
		
		previousSectionOfCollections = nil // SIDE EFFECT
		
		tableView.reloadRows(at: [indexPathOfCombinedCollection], with: .fade)
	}
	
}
