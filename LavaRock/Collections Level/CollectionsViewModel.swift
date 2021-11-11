//
//  CollectionsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct CollectionsViewModel {
	// LibraryViewModel
	let lastSpecificContainer: LibraryContainer? = nil
	let context: NSManagedObjectContext
	var groups: [GroupOfLibraryItems]
}

extension CollectionsViewModel: LibraryViewModel {
	static let entityName = "Collection"
	static let numberOfSectionsAboveLibraryItems = FeatureFlag.allRow ? 1 : 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 0
	
	func refreshed() -> Self {
		return Self(context: context)
	}
}

extension CollectionsViewModel {
	
	init(context: NSManagedObjectContext) {
		self.context = context
		
		groups = [
			GroupOfCollectionsOrAlbums(
				entityName: Self.entityName,
				container: nil,
				context: context)
		]
	}
	
	private static let indexOfOnlyGroup = 0 //
	
	var group: GroupOfLibraryItems { groups[Self.indexOfOnlyGroup] } //
	
	private func updatedWithItemsInOnlyGroup(_ newItems: [NSManagedObject]) -> Self {
		var twin = self
		twin.groups[Self.indexOfOnlyGroup].setItems(newItems)
		return twin
	}
	
	// MARK: - Editing
	
	// Return value: whether this method changed the Collection's title.
	// Works for renaming an existing Collection, after combining Collections, and after making a new Collection.
	func rename(
		at indexPath: IndexPath,
		proposedTitle: String?
	) -> Bool {
		guard let collection = item(at: indexPath) as? Collection else {
			return false
		}
		let didChangeTitle = collection.rename(toProposedTitle: proposedTitle)
		return didChangeTitle
	}
	
//	func isPreviewingCombineCollections() -> Bool {
//		return groupOfCollectionsBeforeCombining != nil
//	}
	
	func itemsAfterCombiningCollections(
		from selectedIndexPaths: [IndexPath],
		into indexPathOfCombinedCollection: IndexPath
	) -> [NSManagedObject] {
//		// Save the existing GroupOfCollectionsOrAlbums for if we need to revert, and to prevent ourselves from starting another preview while we're already previewing.
//		groupOfCollectionsBeforeCombining = group // SIDE EFFECT
		
		// Create the combined Collection.
		let selectedCollections = selectedIndexPaths.compactMap { item(at: $0) as? Collection }
		let indexOfCombinedCollection = indexOfItemInGroup(forRow: indexPathOfCombinedCollection.row)
		let combinedCollection = Collection( // SIDE EFFECT
			combining_withoutDeletingOrReindexing: selectedCollections,
			title: LocalizedString.combinedCollectionDefaultTitle,
			index: Int64(indexOfCombinedCollection),
			context: context)
		// WARNING: We still need to delete empty Collections and reindex all Collections.
		// Do that later, when we commit, because if we revert, we have to restore the original Collections, and Core Data warns you if you mutate managed objects after deleting them.
		try? context.obtainPermanentIDs( // SIDE EFFECT
			for: [combinedCollection]) // So that the "now playing" indicator can appear on the combined Collection.
		
		var newItems = group.items
		let indicesOfSelectedCollections = selectedIndexPaths.map {
			indexOfItemInGroup(forRow: $0.row)
		}
		indicesOfSelectedCollections.reversed().forEach { newItems.remove(at: $0) }
		newItems.insert(combinedCollection, at: indexOfCombinedCollection)
		return newItems
	}
	
	// MARK: - “Moving Albums” Mode
	
	private static let indexOfNewCollection = 0
	var indexPathOfNewCollection: IndexPath { // TO DO: Should be static
		return indexPathFor(
			indexOfItemInGroup: Self.indexOfNewCollection,
			indexOfGroup: Self.indexOfOnlyGroup)
	}
	
	func updatedAfterCreatingNewCollectionInOnlyGroup(
		suggestedTitle: String?
	) -> (Self, IndexPath) {
		let newCollection = Collection(context: context)
		newCollection.title = suggestedTitle ?? LocalizedString.newCollectionDefaultTitle
		// When we call setItemsAndMoveRows, the property observer will set the "index" attribute of each Collection for us.
		
		var newItems = group.items
		newItems.insert(newCollection, at: Self.indexOfNewCollection)
		
		let twin = updatedWithItemsInOnlyGroup(newItems)
		let indexPath = indexPathOfNewCollection
		return (twin, indexPath)
	}
	
	func updatedAfterDeletingNewCollection() -> Self {
		let newItems = itemsAfterDeletingNewCollection()
		
		let twin = updatedWithItemsInOnlyGroup(newItems)
		return twin
	}
	
	private func itemsAfterDeletingNewCollection() -> [NSManagedObject] {
		let oldItems = group.items
		guard
			let collection = oldItems[Self.indexOfNewCollection] as? Collection,
			collection.isEmpty()
		else {
			return oldItems
		}
		
		context.delete(collection)
		
		var newItems = group.items
		newItems.remove(at: Self.indexOfNewCollection)
		return newItems
	}
	
}
