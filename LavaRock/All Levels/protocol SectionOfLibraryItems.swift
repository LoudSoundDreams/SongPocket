//
//  protocol SectionOfLibraryItems.swift
//  LavaRock
//
//  Created by h on 2021-07-02.
//

import CoreData

protocol SectionOfLibraryItems {
	var entityName: String { get }
	var container: NSManagedObject? { get }
	
	var items: [NSManagedObject] { get }
	/*
	 Force callers to use `setItems` rather than modifying `items` directly. That helps callers keep `items` in a coherent state by forcing them to finalize their changes explicitly.
	 
	 It would be nice to make `items` `private(set)`, but then it couldn't satisfy the protocol requirement. Instead, include …
	 var items: [NSManagedObject] { private_items }
	 private var private_items = [NSManagedObject]()
	 
	 For safety, disable the default memberwise initializer (for structs), to prevent callers from initializing `private_items` incorrectly. Include this in your custom initializer:
	 private_items = fetchedItems()
	 
	 You can also use …
	 private(set) lazy var private_items = fetchedItems()
	 … but you'll have to make `items` `mutating get`, and you'll still have to disable the default memberwise initializer to be safe.
	 
	 You should also give `private_items` a property observer that sets the `index` attribute on each NSManagedObject, exactly like [LibraryItem].reindex():
	 //	didSet {
	 //		for currentIndex in private_items.indices {
	 //			private_items[currentIndex].setValue(Int64(currentIndex), forKey: "index")
	 //		}
	 //	}
	 */
	
	mutating func setItems(_ newItems: [NSManagedObject])
	// Helps callers keep `items` in a coherent state by forcing them to finalize their changes explicitly.
	// Note: Also reindexes the `index` attribute on each item.
	
	func itemsFetched(
		via managedObjectContext: NSManagedObjectContext
	) -> [NSManagedObject]
	func refreshContainer(
		via managedObjectContext: NSManagedObjectContext)
}

extension SectionOfLibraryItems {
	
	func isEmpty() -> Bool {
		return items.isEmpty
	}
	
	func itemsFetched(
		via managedObjectContext: NSManagedObjectContext
	) -> [NSManagedObject] {
		let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		if let container = container {
			fetchRequest.predicate = NSPredicate(format: "container == %@", container)
		}
		return managedObjectContext.objectsFetched(for: fetchRequest)
	}
	
	func refreshContainer(
		via managedObjectContext: NSManagedObjectContext
	) {
		guard let container = container else { return }
		managedObjectContext.refresh(container, mergeChanges: true)
	}
	
}
