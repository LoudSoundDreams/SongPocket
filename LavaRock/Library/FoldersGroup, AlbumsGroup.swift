//
//  FoldersGroup, AlbumsGroup.swift
//  LavaRock
//
//  Created by h on 2021-03-04.
//

import CoreData

extension FoldersGroup: LibraryGroup {}
struct FoldersGroup {
	// `LibraryGroup`
	let container: NSManagedObject? = nil
	var items: [NSManagedObject] {
		didSet {
			_reindex()
		}
	}
	
	init(context: NSManagedObjectContext) {
		items = Collection.allFetched(sorted: true, context: context)
	}
}

extension AlbumsGroup: LibraryGroup {}
struct AlbumsGroup {
	// `LibraryGroup`
	let container: NSManagedObject?
	var items: [NSManagedObject] {
		didSet {
			_reindex()
		}
	}
	
	init(
		folder: Collection?,
		context: NSManagedObjectContext
	) {
		items = Album.allFetched(sorted: true, inCollection: folder, context: context)
		self.container = folder
	}
}
