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
	let numberOfPresections = 0
	private(set) var numberOfPrerowsPerSection: Int
	var groups: [GroupOfLibraryItems]
}

extension CollectionsViewModel: LibraryViewModel {
	static let entityName = "Collection"
	
	func viewContainerIsSpecific() -> Bool {
		return true
	}
	
	func bigTitle() -> String {
		return FeatureFlag.multicollection ? LocalizedString.sections : LocalizedString.collections
	}
	
	func allowsSortOption(
		_ sortOption: LibraryTVC.SortOption,
		forItems items: [NSManagedObject]
	) -> Bool {
		switch sortOption {
		case .title:
			return true
		case
				.newestFirst,
				.oldestFirst,
				.trackNumber:
			return false
		case
				.random,
				.reverse:
			return true
		}
	}
	
	func updatedWithRefreshedData() -> Self {
		return Self(
			context: context,
			numberOfPrerowsPerSection: numberOfPrerowsPerSection)
	}
}

extension CollectionsViewModel {
	
	init(
		context: NSManagedObjectContext,
		numberOfPrerowsPerSection: Int
	) {
		self.context = context
		self.numberOfPrerowsPerSection = numberOfPrerowsPerSection
		
		groups = [
			GroupOfCollectionsOrAlbums(
				entityName: Self.entityName,
				container: nil,
				context: context)
		]
	}
	
	func collectionNonNil(at indexPath: IndexPath) -> Collection {
		return itemNonNil(at: indexPath) as! Collection
	}
	
	private static let indexOfOnlyGroup = 0
	
	var group: GroupOfLibraryItems { groups[Self.indexOfOnlyGroup] }
	
	private func updatedWithItemsInOnlyGroup(_ newItems: [NSManagedObject]) -> Self {
		var twin = self
		twin.groups[Self.indexOfOnlyGroup].setItems(newItems)
		return twin
	}
	
	// MARK: - Renaming
	
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
	
	// MARK: Combining
	
	func updatedAfterCombining_inNewChildContext(
		fromInOrder collections: [Collection],
		into indexPathOfCombined: IndexPath,
		title: String
	) -> Self {
		let collectionIDs = collections.map { $0.objectID }
		let index = indexOfItemInGroup(forRow: indexPathOfCombined.row)
		let childContext = NSManagedObjectContext.withParent(context)
		childContext.parent = context
		let combinedCollection = Collection(
			combiningCollectionsInOrderWith: collectionIDs,
			title: title,
			index: Int64(index),
			context: childContext)
		
		try? childContext.obtainPermanentIDs(for: [combinedCollection]) // So that we don't unnecessarily remove and reinsert the row later.
		
		let twin = Self.init(
			context: childContext,
			numberOfPrerowsPerSection: numberOfPrerowsPerSection)
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
	
	// MARK: - “Move Albums” Sheet
	
	private static let indexOfNewCollection = 0
	var indexPathOfNewCollection: IndexPath {
		return indexPathFor(
			indexOfItemInGroup: Self.indexOfNewCollection,
			indexOfGroup: Self.indexOfOnlyGroup)
	}
	
	func updatedAfterCreating(title: String) -> (Self, IndexPath) {
		let newCollection = Collection(context: context)
		newCollection.title = title
		// When we call setItemsAndMoveRows, the property observer will set the "index" attribute of each Collection for us.
		
		var newItems = group.items
		newItems.insert(newCollection, at: Self.indexOfNewCollection)
		
		var twin = updatedWithItemsInOnlyGroup(newItems)
		twin.numberOfPrerowsPerSection = 0
		let indexPath = indexPathOfNewCollection
		return (twin, indexPath)
	}
	
	func updatedAfterDeletingNewCollection() -> Self {
		let newItems = itemsAfterDeletingNewCollection()
		
		var twin = updatedWithItemsInOnlyGroup(newItems)
		twin.numberOfPrerowsPerSection = 1
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
