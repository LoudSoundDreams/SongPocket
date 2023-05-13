//
//  FoldersOrAlbumsGroup.swift
//  LavaRock
//
//  Created by h on 2021-03-04.
//

import CoreData

struct FoldersOrAlbumsGroup {
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
extension FoldersOrAlbumsGroup: LibraryGroup {
	mutating func setItems(_ newItems: [NSManagedObject]) {
		items = newItems
	}
	
	init(
		entityName: String,
		container: NSManagedObject?,
		context: NSManagedObjectContext
	) {
		items = Self.itemsFetched( // Doesn’t trigger the property observer
			entityName: entityName,
			container: container,
			context: context)
		self.container = container
	}
}
