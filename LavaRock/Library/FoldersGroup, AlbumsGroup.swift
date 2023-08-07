//
//  FoldersGroup, AlbumsGroup.swift
//  LavaRock
//
//  Created by h on 2021-03-04.
//

import CoreData

struct FoldersGroup {
	// `LibraryGroup`
	let container: NSManagedObject? = nil
	private(set) var items: [NSManagedObject] {
		didSet {
			items.enumerated().forEach { (currentIndex, libraryItem) in
				libraryItem.setValue(
					Int64(currentIndex),
					forKey: "index")
			}
		}
	}
}
extension FoldersGroup: LibraryGroup {
	mutating func setItems(_ newItems: [NSManagedObject]) {
		items = newItems
	}
	
	init(context: NSManagedObjectContext) {
		items = Collection.allFetched(sorted: true, context: context)
	}
}

struct AlbumsGroup {
	// `LibraryGroup`
	let container: NSManagedObject?
	private(set) var items: [NSManagedObject] {
		didSet {
			items.enumerated().forEach { (currentIndex, libraryItem) in
				libraryItem.setValue(
					Int64(currentIndex),
					forKey: "index")
			}
		}
	}
}
extension AlbumsGroup: LibraryGroup {
	mutating func setItems(_ newItems: [NSManagedObject]) {
		items = newItems
	}
	
	init(
		folder: Collection?,
		context: NSManagedObjectContext
	) {
		items = Album.allFetched(sorted: true, inCollection: folder, context: context)
		self.container = folder
	}
}
