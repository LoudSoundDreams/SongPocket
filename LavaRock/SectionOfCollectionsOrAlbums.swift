//
//  SectionOfCollectionsOrAlbums.swift
//  LavaRock
//
//  Created by h on 2021-03-04.
//

import CoreData

struct SectionOfCollectionsOrAlbums: SectionOfLibraryItems {
	
	init(
		entityName: String,
		container: NSManagedObject?,
		context: NSManagedObjectContext
	) {
		self.entityName = entityName
		self.container = container
		
		private_items = itemsFetched(context: context) // Doesn't trigger the property observer
	}
	
	// MARK: - SectionOfLibraryItems
	
	// Constants
	let entityName: String
	let container: NSManagedObject?
	
	// Variables
	var items: [NSManagedObject] { private_items }
	private var private_items = [NSManagedObject]() {
		didSet {
			private_items.indices.forEach { currentIndex in
				private_items[currentIndex].setValue(
					Int64(currentIndex),
					forKey: "index")
			}
		}
	}
	
	mutating func setItems(_ newItems: [NSManagedObject]) {
		private_items = newItems
	}
	
}
