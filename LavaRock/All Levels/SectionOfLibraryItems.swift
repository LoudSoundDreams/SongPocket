//
//  SectionOfLibraryItems.swift
//  LavaRock
//
//  Created by h on 2021-03-04.
//
/*
import CoreData

struct SectionOfLibraryItems {
	
	// MARK: - Properties
	
	// MARK: Constants
	
	let container: NSManagedObject? // Switch to associatedtype?
	let managedObjectContext: NSManagedObjectContext
	let entityName: String
	
	// MARK: Variables
	
	lazy var items = fetchedItems() {
		didSet {
			for index in 0 ..< items.count {
				items[index].setValue(Int64(index), forKey: "index") // Switch to proper type-checking
			}
		}
	}
	
	// Computed properties
//	var isEmpty: Bool { items.isEmpty } // Nonsensical build error: "Cannot use mutating getter on immutable value: 'self' is immutable"
	var fetchRequest: NSFetchRequest<NSManagedObject> {
		let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
		request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		if let container = container {
			request.predicate = NSPredicate(format: "container == %@", container)
		}
		return request
	}
	
	// MARK: - Methods
	
	func fetchedItems() -> [NSManagedObject] {
		return managedObjectContext.objectsFetched(for: fetchRequest)
	}
	
}
*/
