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
	var groups: ColumnOfLibraryItems
}
extension AlbumsViewModel: LibraryViewModel {
	func prerowCount() -> Int { return 0 }
	func prerowIdentifiers() -> [AnyHashable] { return [] }
	
	// Similar to counterpart in `SongsViewModel`.
	func updatedWithFreshenedData() -> Self {
		let freshenedCollection: Collection? = {
			guard
				let collection,
				!collection.wasDeleted() // WARNING: You must check this, or the initializer will create groups with no items.
			else {
				return nil
			}
			return collection
		}()
		return Self(
			collection: freshenedCollection,
			context: context)
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
	
	// MARK: - “Move albums” sheet
	
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
