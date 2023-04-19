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
	let context: NSManagedObjectContext
	var numberOfPrerowsPerSection: Int {
		prerowsInEachSection.count
	}
	var groups: ColumnOfLibraryItems
	
	enum Prerow {
		case createCollection
	}
	var prerowsInEachSection: [Prerow]
}
extension CollectionsViewModel: LibraryViewModel {
	static let entityName = "Collection"
	
	func bigTitle() -> String {
		return LRString.folders
	}
	
	func prerowIdentifiersInEachSection() -> [AnyHashable] {
		return prerowsInEachSection
	}
	
	func allowsSortCommand(
		_ sortCommand: SortCommand,
		forItems items: [NSManagedObject]
	) -> Bool {
		switch sortCommand {
			case .folder_name:
				return true
			case
					.album_newestRelease,
					.song_trackNumber:
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
		let row = indexPath.row
		if row < numberOfPrerowsPerSection {
			return .prerow(prerowsInEachSection[row])
		} else {
			return .collection
		}
	}
	
	func numberOfRows() -> Int {
		let group = libraryGroup()
		return numberOfPrerowsPerSection + group.items.count
	}
	
	private var group: LibraryGroup {
		get {
			groups[0]
		}
		set {
			groups[0] = newValue
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
	
	// MARK: - “Move Albums” Sheet
	
	private static let indexOfNewCollection = 0
	var indexPathOfNewCollection: IndexPath {
		return indexPathFor(itemIndex: Self.indexOfNewCollection)
	}
	
	func updatedAfterCreating() -> Self {
		let newCollection = Collection(context: context)
		newCollection.title = LRString.untitledFolder
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
