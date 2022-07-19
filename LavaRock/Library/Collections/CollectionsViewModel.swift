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
	let numberOfPresections = Section_I(0)
	var numberOfPrerowsPerSection: Row_I { Row_I(prerowsInEachSection.count) }
	var groups: ColumnOfLibraryItems
	
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
		? LRString.sections
		: LRString.collections
	}
	
	func prerowIdentifiersInEachSection() -> [AnyHashable] {
		return prerowsInEachSection
	}
	
	func allowsSortOption(
		_ sortOption: LibrarySortOption,
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
				.shuffle,
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
			CollectionsOrAlbumsGroup(
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
		let row = indexPath.row_i
		if row < numberOfPrerowsPerSection {
			return .prerow(prerowsInEachSection[row.value])
		} else {
			return .collection
		}
	}
	
	private static let indexOfOnlyGroup = 0
	
	var group: LibraryGroup {
		get {
			groups[Self.indexOfOnlyGroup]
		}
		set {
			groups[Self.indexOfOnlyGroup] = newValue
		}
	}
	
	private func updatedWithItemsInOnlyGroup(_ newItems: [NSManagedObject]) -> Self {
		var twin = self
		twin.group.setItems(newItems)
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
		let index = itemIndex(for: indexPathOfCombined.row_i)
		let childContext = NSManagedObjectContext(.mainQueue)
		childContext.parent = context
		let combinedCollection = Collection(
			combiningCollectionsInOrderWith: collectionIDs,
			title: title,
			index: Int64(index.__),
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
			itemIndex: ItemIndex(Self.indexOfNewCollection),
			groupIndex: GroupIndex(Self.indexOfOnlyGroup))
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
