//
//  CollectionsViewModel.swift
//  CollectionsViewModel
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct CollectionsViewModel: LibraryViewModel {
	
	// MARK: - LibraryViewModel
	
	static let entityName = "Collection"
	static let numberOfSectionsAboveLibraryItems = FeatureFlag.allRow ? 1 : 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 0
	
	let context: NSManagedObjectContext
	
	weak var reflector: LibraryViewModelReflecting?
	
	var groups: [GroupOfLibraryItems]
	
	func navigationItemTitleOptional() -> String? {
		FeatureFlag.allRow ? LocalizedString.library : nil
	}
	
	// MARK: - Miscellaneous
	
	static let indexOfGroup = 0 //
	
	var group: GroupOfLibraryItems { groups[Self.indexOfGroup] }
	
	init(
		context: NSManagedObjectContext,
		reflector: LibraryViewModelReflecting
	) {
		self.context = context
		self.reflector = reflector
		groups = [
			GroupOfCollectionsOrAlbums(
				entityName: Self.entityName,
				container: nil,
				context: context)
		]
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
		
		// Make a new data source.
		var newItems = group.items
		let indicesOfSelectedCollections = selectedIndexPaths.map {
			indexOfItemInGroup(forRow: $0.row)
		}
		indicesOfSelectedCollections.reversed().forEach { newItems.remove(at: $0) }
		newItems.insert(combinedCollection, at: indexOfCombinedCollection)
		return newItems
	}
	
	// MARK: - “Moving Albums” Mode
	
	func itemsAfterMakingNewCollection(
		suggestedTitle: String?,
		indexOfNewCollection: Int
	) -> [NSManagedObject] { // ? [Collection]
		let newCollection = Collection(context: context)
		newCollection.title = suggestedTitle ?? LocalizedString.newCollectionDefaultTitle
		// When we call setItemsAndMoveRows, the property observer will set the "index" attribute of each Collection for us.
		
		var newItems = group.items
		newItems.insert(newCollection, at: indexOfNewCollection)
		return newItems
	}
	
	func itemsAfterDeletingCollectionIfEmpty(
		indexOfCollection: Int
	) -> [NSManagedObject] { // ? [Collection]
		let oldItems = group.items
		guard
			let collection = oldItems[indexOfCollection] as? Collection,
			collection.isEmpty()
		else {
			return oldItems
		}
		
		context.delete(collection)
		
		var newItems = group.items
		newItems.remove(at: indexOfCollection)
		return newItems
	}
	
}
