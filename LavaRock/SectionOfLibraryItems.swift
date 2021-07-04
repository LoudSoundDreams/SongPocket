//
//  SectionOfLibraryItems.swift
//  LavaRock
//
//  Created by h on 2021-03-04.
//

import CoreData

struct SectionOfLibraryItems: SectionOfLibraryItemsProtocol {
	
	init(
		entityName: String,
		managedObjectContext: NSManagedObjectContext,
		container: NSManagedObject?
	) {
		self.entityName = entityName
		self.managedObjectContext = managedObjectContext
		self.container = container
		
		private_items = fetchedItems()
	}
	
	// MARK: - SectionOfLibraryItemsProtocol
	
	// Constants
	let entityName: String
	let managedObjectContext: NSManagedObjectContext
	let container: NSManagedObject?
	
	// Variables
	var items: [NSManagedObject] { private_items }
	private var private_items = [NSManagedObject]() {
		didSet {
			for currentIndex in private_items.indices {
				private_items[currentIndex].setValue(Int64(currentIndex), forKey: "index")
			}
		}
	}
	
	mutating func setItems(_ newItems: [NSManagedObject]) {
		private_items = newItems
	}
	
}
