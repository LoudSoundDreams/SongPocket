//
//  AlbumsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import CoreData

struct AlbumsViewModel {
	let collection: Collection?
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var groups: [LibraryGroup]
}
extension AlbumsViewModel: LibraryViewModel {
	func itemIndex(forRow row: Int) -> Int { return row }
	func rowsForAllItems() -> [Int] {
		guard !isEmpty() else {
			return []
		}
		return libraryGroup().items.indices.map { $0 }
	}
	func row(forItemIndex itemIndex: Int) -> Int { return itemIndex }
	
	// Similar to counterpart in `SongsViewModel`.
	func updatedWithFreshenedData() -> Self {
		let freshenedCollection: Collection? = {
			// WARNING: You must check this, or the initializer will create groups with no items.
			guard let collection, !collection.wasDeleted() else {
				return nil
			}
			return collection
		}()
		return Self(
			collection: freshenedCollection,
			context: context)
	}
	
	func rowIdentifiers() -> [AnyHashable] {
		return groups[0].items.map { $0.objectID }
	}
}
extension AlbumsViewModel {
	init(
		collection: Collection?,
		context: NSManagedObjectContext
	) {
		self.collection = collection
		
		self.context = context
		guard let collection else {
			groups = []
			return
		}
		groups = [
			AlbumsGroup(
				collection: collection,
				context: context)
		]
	}
	
	func albumNonNil(atRow: Int) -> Album {
		return itemNonNil(atRow: atRow) as! Album
	}
	
	// MARK: - “Move” sheet
	
	func updatedAfterInserting(
		albumsWith albumIDs: [NSManagedObjectID]
	) -> Self {
		let group = libraryGroup()
		let destination = group.container as! Collection
		
		destination.unsafe_InsertAlbums_WithoutDeleteOrReindexSources(
			albumIDs: albumIDs,
			via: context)
		context.deleteEmptyCollections()
		
		return AlbumsViewModel(
			collection: collection,
			context: context)
	}
}
