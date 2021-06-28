//
//  SectionOfLibraryItems.swift
//  LavaRock
//
//  Created by h on 2021-03-04.
//

import CoreData

struct SectionOfLibraryItems {
	
	// MARK: - Properties
	
	// MARK: Constants
	
	let managedObjectContext: NSManagedObjectContext
	let entityName: String
	let container: NSManagedObject?
	
	// MARK: Variables
	
	private(set) lazy var items = fetchedItems() {
		didSet {
			// Needs to match [LibraryItem].reindex().
			for currentIndex in items.indices { // The truth for the order of items is their order in this array, not the "index" attribute of each NSManagedObject, because the UI follows this array.
				items[currentIndex].setValue(Int64(currentIndex), forKey: "index")
			}
		}
	}
	
	// MARK: - Methods
	
	mutating func setItems(_ newItems: [NSManagedObject]) {
		items = newItems
	}
	
	func fetchedItems() -> [NSManagedObject] {
		let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		if let container = container {
			fetchRequest.predicate = NSPredicate(format: "container == %@", container)
		}
		
		return managedObjectContext.objectsFetched(for: fetchRequest)
	}
	
	func refreshContainer() {
		guard let container = container else { return }
		managedObjectContext.refresh(container, mergeChanges: true)
	}
	
}
