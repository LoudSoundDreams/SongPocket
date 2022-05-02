//
//  GroupOfSongs.swift
//  LavaRock
//
//  Created by h on 2021-07-02.
//

import CoreData

struct GroupOfSongs {
	// `GroupOfLibraryItems`
	let container: NSManagedObject?
	var items: [NSManagedObject] { private_items }
	private var private_items: [NSManagedObject] = [] {
		didSet {
			private_items.enumerated().forEach { (currentIndex, libraryItem) in
				libraryItem.setValue(
					Int64(currentIndex),
					forKey: "Index")
			}
		}
	}
	init(
		entityName: String,
		container: NSManagedObject?,
		context: NSManagedObjectContext
	) {
		self.container = container
		
		private_items = itemsFetched( // Doesn’t trigger the property observer
			entityName: entityName,
			context: context)
	}
}
extension GroupOfSongs: GroupOfLibraryItems {
	mutating func setItems(_ newItems: [NSManagedObject]) {
		private_items = newItems
	}
}
