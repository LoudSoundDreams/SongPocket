//
//  SongsGroup.swift
//  LavaRock
//
//  Created by h on 2021-07-02.
//

import CoreData

struct SongsGroup {
	// `LibraryGroup`
	let container: NSManagedObject?
	private(set) var items: [NSManagedObject] {
		didSet {
			items.enumerated().forEach { (currentIndex, libraryItem) in
				libraryItem.setValue(
					Int64(currentIndex),
					forKey: "Index")
			}
		}
	}
}
extension SongsGroup: LibraryGroup {
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
