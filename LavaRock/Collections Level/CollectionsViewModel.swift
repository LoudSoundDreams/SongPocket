//
//  CollectionsViewModel.swift
//  CollectionsViewModel
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct CollectionsViewModel: LibraryViewModel {
	
	static let indexOfGroup = 0
	
	let numberOfSectionsAboveLibraryItems = 0 //
	let numberOfRowsAboveLibraryItemsInEachSection = 0
	
	var groups: [GroupOfLibraryItems] //
//	var groupOfCollectionsBeforeCombining: GroupOfLibraryItems?
	
	var group: GroupOfLibraryItems { groups[Self.indexOfGroup] }
	
	// MARK: - Editing
	
	// MARK: Allowing
	
	func allowsCombine(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		guard !isEmpty() else {
			return false
		}
		
		return selectedIndexPaths.count >= 2
	}
	
	// MARK: Combining
	
//	func isPreviewingCombineCollections() -> Bool {
//		return groupOfCollectionsBeforeCombining != nil
//	}
	
	func itemsAfterCombiningCollections(
		from selectedIndexPaths: [IndexPath],
		into indexPathOfCombinedCollection: IndexPath,
		context: NSManagedObjectContext
	) -> [NSManagedObject] {
//		// Save the existing GroupOfCollectionsOrAlbums for if we need to revert, and to prevent ourselves from starting another preview while we're already previewing.
//		groupOfCollectionsBeforeCombining = group // SIDE EFFECT
		
		// Create the combined Collection.
		let selectedCollections = selectedIndexPaths.compactMap { item(for: $0) as? Collection }
		let indexOfCombinedCollection = indexOfItemInGroup(forRow: indexPathOfCombinedCollection.row)
		let combinedCollection = Collection.makeByCombining_withoutDeletingOrReindexing( // SIDE EFFECT
			selectedCollections,
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
	
	// MARK: Making New
	
	func itemsAfterMakingNewCollection(
		suggestedTitle: String?,
		indexOfNewCollection: Int,
		context: NSManagedObjectContext
	) -> [NSManagedObject] { // ? [Collection]
		let newCollection = Collection(context: context)
		newCollection.title = suggestedTitle ?? LocalizedString.newCollectionDefaultTitle
		// When we call setItemsAndRefresh, the property observer will set the "index" attribute of each Collection for us.
		
		var newItems = group.items
		newItems.insert(newCollection, at: indexOfNewCollection)
		return newItems
	}
	
	// MARK: Deleting New
	
	func itemsAfterDeletingCollection(
		indexOfCollection: Int,
		context: NSManagedObjectContext
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
	
	// MARK: Renaming
	
	// Return value: whether this method changed the Collection's title.
	func renameCollection(
		proposedTitle: String?,
		indexOfCollection: Int,
		context: NSManagedObjectContext
	) -> Bool {
		guard let collection = group.items[indexOfCollection] as? Collection else {
			return false //
		}
		
		let oldTitle = collection.title
		if let newTitle = Collection.validatedTitleOptional(from: proposedTitle) {
			collection.title = newTitle
		}
		let didChangeTitle = oldTitle != collection.title
		
		return didChangeTitle
	}
	
}
