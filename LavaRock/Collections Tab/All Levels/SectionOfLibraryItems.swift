//
//  SectionOfLibraryItems.swift
//  LavaRock
//
//  Created by h on 2021-03-04.
//

import CoreData

struct SectionOfLibraryItems {
	
	let container: NSManagedObject? // associatedtype?
	let managedObjectContext: NSManagedObjectContext
	let entityName: String
	
	var items = [NSManagedObject]() {
		didSet {
			for index in 0 ..< items.count {
				items[index].setValue(Int64(index), forKey: "index") // Use proper type-checking
			}
		}
	}
	
	init( // Can we add code to the automatic memberwise initializer?
		container: NSManagedObject?,
		managedObjectContext: NSManagedObjectContext,
		entityName: String
	) {
		self.container = container
		self.managedObjectContext = managedObjectContext
		self.entityName = entityName
		
		items = fetchedItems()
	}
//	init() {
//		self.init()
//		
//		items = fetchedItems()
//	}
	
	// Computed properties
	var fetchRequest: NSFetchRequest<NSManagedObject> {
		let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
		request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		if let container = container {
			request.predicate = NSPredicate(format: "container == %@", container)
		}
		return request
	}
	
	func fetchedItems() -> [NSManagedObject] {
		return managedObjectContext.objectsFetched(for: fetchRequest)
	}
}

//extension SectionOfLibraryItems {
//
//	init() {
//		self.init()
//
//		items = fetchedIndexedLibraryItems()
//	}
//
//}

