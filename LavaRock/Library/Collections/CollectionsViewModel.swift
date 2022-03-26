//
//  CollectionsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct CollectionsViewModel {
	// `LibraryViewModel`
	let viewContainer: LibraryViewContainer = .library
	let context: NSManagedObjectContext
	let numberOfPresections = 0
	var numberOfPrerowsPerSection: Int { prerowsInEachSection.count }
	var groups: [GroupOfLibraryItems]
	
	enum Prerow {
		case createCollection
	}
	var prerowsInEachSection: [Prerow]
}
extension CollectionsViewModel: LibraryViewModel {
	static let entityName = "Collection"
	
	func viewContainerIsSpecific() -> Bool {
		return true
	}
	
	func bigTitle() -> String {
		return Enabling.multicollection
		? LocalizedString.sections
		: LocalizedString.collections
	}
	
	@MainActor
	func itemIsOrContainsCurrentSong(anyIndexPath: IndexPath) -> Bool {
		guard
			let rowCollection = itemOptional(at: anyIndexPath) as? Collection,
			let currentSong = Player.shared.currentSong(context: context)
		else {
			return false
		}
		return rowCollection.objectID == currentSong.container?.container?.objectID
	}
	
	func prerowIdentifiersInEachSection() -> [AnyHashable] {
		return prerowsInEachSection
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
	
	func updatedWithFreshenedData() -> Self {
		return Self(
			context: context,
			prerowsInEachSection: prerowsInEachSection)
	}
}
extension CollectionsViewModel {
	init(
		context: NSManagedObjectContext,
		prerowsInEachSection: [Prerow]
	) {
		self.context = context
		self.prerowsInEachSection = prerowsInEachSection
		
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
	
	enum RowCase {
		case prerow(Prerow)
		case collection
	}
	func rowCase(for indexPath: IndexPath) -> RowCase {
		let row = indexPath.row
		if row < numberOfPrerowsPerSection {
			let associatedValue = prerowsInEachSection[row]
			return .prerow(associatedValue)
		} else {
			return .collection
		}
	}
	
	private static let indexOfOnlyGroup = 0
	
	var group: GroupOfLibraryItems { groups[Self.indexOfOnlyGroup] }
	
	private func updatedWithItemsInOnlyGroup(_ newItems: [NSManagedObject]) -> Self {
		var twin = self
		twin.groups[Self.indexOfOnlyGroup].setItems(newItems)
		return twin
	}
	
	// MARK: - Renaming
	
	func renameAndReturnDidChangeTitle(
		at indexPath: IndexPath,
		proposedTitle: String?
	) -> Bool {
		guard
			let proposedTitle = proposedTitle,
			proposedTitle != ""
		else {
			return false
		}
		let newTitle = proposedTitle.truncatedIfLonger(than: 256) // In case the user entered a dangerous amount of text
		
		let collection = collectionNonNil(at: indexPath)
		let oldTitle = collection.title
		collection.title = newTitle
		return oldTitle != collection.title
	}
	
	// MARK: Combining
	
	func updatedAfterCombiningInNewChildContext(
		fromInOrder collections: [Collection],
		into indexPathOfCombined: IndexPath,
		title: String
	) -> Self {
		let collectionIDs = collections.map { $0.objectID }
		let index = indexOfItemInGroup(forRow: indexPathOfCombined.row)
		let childContext = NSManagedObjectContext(.mainQueue)
		childContext.parent = context
		let combinedCollection = Collection(
			combiningCollectionsInOrderWith: collectionIDs,
			title: title,
			index: Int64(index),
			context: childContext)
		
		try? childContext.obtainPermanentIDs(for: [combinedCollection]) // So that we don’t unnecessarily remove and reinsert the row later.
		
		let twin = Self.init(
			context: childContext,
			prerowsInEachSection: prerowsInEachSection)
		return twin
	}
	
	// MARK: - “Move Albums” Sheet
	
	private static let indexOfNewCollection = 0
	var indexPathOfNewCollection: IndexPath {
		return indexPathFor(
			indexOfItemInGroup: Self.indexOfNewCollection,
			indexOfGroup: Self.indexOfOnlyGroup)
	}
	
	func updatedAfterCreating(title: String) -> Self {
		let newCollection = Collection(context: context)
		newCollection.title = title
		// When we call `setItemsAndMoveRows`, the property observer will set the `index` attribute of each `Collection` for us.
		
		var newItems = group.items
		newItems.insert(newCollection, at: Self.indexOfNewCollection)
		
		var twin = updatedWithItemsInOnlyGroup(newItems)
		twin.prerowsInEachSection = []
		return twin
	}
	
	func updatedAfterDeletingNewCollection() -> Self {
		let newItems = itemsAfterDeletingNewCollection()
		
		var twin = updatedWithItemsInOnlyGroup(newItems)
		twin.prerowsInEachSection = [.createCollection]
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
