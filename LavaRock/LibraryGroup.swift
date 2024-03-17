//
//  LibraryGroup.swift
//  LavaRock
//
//  Created by h on 2021-07-02.
//

import CoreData

protocol LibraryGroup {
	// Can be empty.
	// You must add a `didSet` that calls `_reindex`.
	var items: [NSManagedObject] { get set }
}
extension LibraryGroup {
	// Must match `[LibraryItem].reindex`.
	func _reindex() {
		items.enumerated().forEach { (currentIndex, libraryItem) in
			libraryItem.setValue(
				Int64(currentIndex),
				forKey: "index")
		}
	}
}

extension CollectionsGroup: LibraryGroup {}
struct CollectionsGroup {
	var items: [NSManagedObject] {
		didSet { _reindex() }
	}
	
	init(context: NSManagedObjectContext) {
		items = Collection.allFetched(sorted: true, context: context)
	}
}

extension AlbumsGroup: LibraryGroup {}
struct AlbumsGroup {
	var items: [NSManagedObject] {
		didSet { _reindex() }
	}
	let containerCollection: Collection?
	
	init(
		collection: Collection?,
		context: NSManagedObjectContext
	) {
		items = Album.allFetched(sorted: true, inCollection: collection, context: context)
		containerCollection = collection
	}
}

extension SongsGroup: LibraryGroup {}
struct SongsGroup {
	var items: [NSManagedObject] {
		didSet { _reindex() }
	}
	let containerAlbum: Album?
	
	init(
		album: Album?,
		context: NSManagedObjectContext
	) {
		items = Song.allFetched(sorted: true, inAlbum: album, context: context)
		containerAlbum = album
	}
}
