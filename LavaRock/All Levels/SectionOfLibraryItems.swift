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
	let container: NSManagedObject?
	let entityName: String // Switch to associatedtype?
	
	// MARK: Variables
	
	lazy var items = fetchedItems() {
		didSet {
			for index in 0 ..< items.count { // The truth for the order of items is their order in this array, not the "index" attribute of each NSManagedObject, because the UI follows this array.
				items[index].setValue(Int64(index), forKey: "index") // Switch to proper type-checking
			}
		}
	}
	
	// Computed properties
//	var isEmpty: Bool { items.isEmpty } // Nonsensical build error: "Cannot use mutating getter on immutable value: 'self' is immutable"
	
	// MARK: - Methods
	
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
