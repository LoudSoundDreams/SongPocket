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
		// When we tap "New Collection" or "Move (Albums) Here", we set `didAlreadyMakeNewCollection` or `didAlreadyCommitMoveAlbums` (respectively) to `true` to prevent unexpected, incorrect sequences of events.
		// However, there's no such problem with the "Combine (Collections)" or "rename (Collection)" buttons.
		
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil.sorted()
		guard let indexPathOfCombinedCollection = selectedIndexPaths.first else { return }
		
		previewCombineCollections(
			from: selectedIndexPaths,
			into: indexPathOfCombinedCollection
		) {
			self.presentDialogToCombineCollections(
				into: indexPathOfCombinedCollection)
		}
	}
	
	private func previewCombineCollections(
		from selectedIndexPaths: [IndexPath],
		into indexPathOfCombinedCollection: IndexPath,
		completion: (() -> ())?
	) {
		// Save the existing SectionOfCollectionsOrAlbums for if we need to revert.
		previousSectionOfCollections = sectionOfLibraryItems // SIDE EFFECT
		
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
		setItemsAndRefreshTableView(newItems: newItems) { // SIDE EFFECT: Reindexes each Collection's `index` attribute
			self.refreshBarButtons() // i really don't want to have to do this manually
			completion?()
		}
	}
	
	private func presentDialogToCombineCollections(
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
		guard
			var copyOfOriginalSection = previousSectionOfCollections,
			let originalItems = previousSectionOfCollections?.items
		else { return }
		previousSectionOfCollections = nil // SIDE EFFECT
		
//		print("")
//		print("All Collections, before revert:")
//		print("")
//		print(Collection.allFetched(via: managedObjectContext))
//		print("")
//		print("Original Collections, before revert:")
//		print("")
//		print(copyOfOriginalSection.items)
		
		// Revert sectionOfLibraryItems to previousSectionOfCollections, but give it the currently onscreen `items`, so that we can animate the change.
		copyOfOriginalSection.setItems(sectionOfLibraryItems.items) // To match the currently onscreen items. Should cause no side effects.
		managedObjectContext.rollback() // SIDE EFFECT
		sectionOfLibraryItems = copyOfOriginalSection // SIDE EFFECT
		
		setItemsAndRefreshTableView(newItems: originalItems) { // SIDE EFFECT
//			print("")
//			print("All Collections, after rollback:")
//			print("")
//			print(Collection.allFetched(via: self.managedObjectContext))
			
//			self.refreshBarButtons() // not necessary; i don't ever want to think about this
			completion?()
		}
	}
	
	private func commitCombineCollection(
//		_ collection: Collection,
		into indexPathOfCombinedCollection: IndexPath,
		withProposedTitle proposedTitle: String?
	) {
		guard let collection = libraryItem(for: indexPathOfCombinedCollection) as? Collection else { return }
		if let newTitle = Collection.titleNotEmptyAndNotTooLong(from: proposedTitle) {
			collection.title = newTitle
		}
		
//		print("")
//		print("Before cleanup:")
//		print("")
//		print(Collection.allFetched(via: managedObjectContext))
		
		Collection.deleteAllEmpty(via: managedObjectContext)
		managedObjectContext.tryToSave()
		
		previousSectionOfCollections = nil // SIDE EFFECT
		
		tableView.reloadRows(at: [indexPathOfCombinedCollection], with: .fade)
	}
	
}
