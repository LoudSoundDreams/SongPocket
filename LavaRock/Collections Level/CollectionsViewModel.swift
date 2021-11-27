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
	let viewContainer: LibraryViewContainer = .library
	let context: NSManagedObjectContext
	var groups: [GroupOfLibraryItems]
}

extension CollectionsViewModel: LibraryViewModel {
	static let entityName = "Collection"
	static let numberOfSectionsAboveLibraryItems = 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 0
	
	var viewContainerIsSpecific: Bool {
		return true
	}
	var navigationItemTitle: String {
		FeatureFlag.multicollection ? LocalizedString.sections : LocalizedString.collections
	}
	
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
	// Works for renaming an existing Collection, after combining Collections, and after creating a new Collection.
	func rename(
		at indexPath: IndexPath,
		proposedTitle: String?
	) -> Bool {
		guard let collection = itemNonNil(at: indexPath) as? Collection else {
			return false
		}
		let oldTitle = collection.title
		collection.tryToRename(proposedTitle: proposedTitle)
		let newTitle = collection.title
		return oldTitle != newTitle
	}
	
	func updatedAfterCombining_inNewChildContext(
		fromCollectionsInOrder collections: [Collection],
		into indexPathOfCombined: IndexPath,
		title: String
	) -> Self {
		let collectionIDs = collections.map { $0.objectID }
		let index = indexOfItemInGroup(forRow: indexPathOfCombined.row)
		let childContext = NSManagedObjectContext.withParent(context)
		childContext.parent = context
		let combinedCollection = Collection(
			combiningCollectionsinOrderWith: collectionIDs,
			title: title,
			index: Int64(index),
			context: childContext)
		
		try? childContext.obtainPermanentIDs(for: [combinedCollection]) // So that we don't unnecessarily remove and reinsert the row later.
		
		let twin = Self.init(context: childContext)
		return twin
	}
	
	func smartTitle(combining collections: [Collection]) -> String? {
		guard let firstTitle = collections.first?.title else {
			return nil
		}
		if collections.dropFirst().allSatisfy({ $0.title == firstTitle }) {
			return firstTitle
		} else {
			return nil
		}
	}
	
	// MARK: - “Moving Albums” Mode
	
	private static let indexOfNewCollection = 0
	static let indexPathOfNewCollection = indexPathFor(
		indexOfItemInGroup: Self.indexOfNewCollection,
		indexOfGroup: Self.indexOfOnlyGroup)
	
	func updatedAfterCreating(title: String) -> (Self, IndexPath) {
		let newCollection = Collection(context: context)
		newCollection.title = title
		// When we call setItemsAndMoveRows, the property observer will set the "index" attribute of each Collection for us.
		
		var newItems = group.items
		newItems.insert(newCollection, at: Self.indexOfNewCollection)
		
		let twin = updatedWithItemsInOnlyGroup(newItems)
		let indexPath = Self.indexPathOfNewCollection
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
