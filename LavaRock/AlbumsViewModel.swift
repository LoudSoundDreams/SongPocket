//
//  AlbumsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import CoreData

struct AlbumsViewModel {
	let collection: Collection
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var group: LibraryGroup
}
extension AlbumsViewModel: LibraryViewModel {
	func itemIndex(forRow row: Int) -> Int { return row }
	func rowsForAllItems() -> [Int] {
		guard !isEmpty() else {
			return []
		}
		return group.items.indices.map { $0 }
	}
	func row(forItemIndex itemIndex: Int) -> Int { return itemIndex }
	
	// Similar to counterpart in `SongsViewModel`.
	func updatedWithFreshenedData() -> Self {
		return Self(collection: collection, context: context)
	}
	
	func rowIdentifiers() -> [AnyHashable] {
		return group.items.map { $0.objectID }
	}
}
extension AlbumsViewModel {
	init(
		collection: Collection,
		context: NSManagedObjectContext
	) {
		self.collection = collection
		self.context = context
		group = AlbumsGroup(collection: collection, context: context)
	}
	
	func albumNonNil(atRow: Int) -> Album {
		return itemNonNil(atRow: atRow) as! Album
	}
	
	// MARK: - “Move” sheet
	
	func updatedAfterInserting(
		albumsWith albumIDs: [NSManagedObjectID]
	) -> Self {
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
