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
	let container: NSManagedObject? // Switch to proper type-checking
	let entityName: String
	
	// MARK: Variables
	
	private(set) lazy var items = fetchedItems() {
		didSet {
			for index in 0 ..< items.count { // The truth for the order of items is their order in this array, not the "index" attribute of each NSManagedObject, because the UI follows this array.
				items[index].setValue(Int64(index), forKey: "index") // Switch to proper type-checking
			}
		}
	}
	
	// MARK: - Methods
	
	mutating func setItems(_ newItems: [NSManagedObject]) {
		items = newItems
	}
	
	func fetchedItems() -> [NSManagedObject] { // Switch to proper type-checking
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
	
	static func indexesOfDeletesInsertsAndMoves(
		oldItems: [NSManagedObject],
		newItems: [NSManagedObject]
	) -> (
		deletes: [Int],
		inserts: [Int],
		moves: [(Int, Int)]
	) {
		let difference = newItems.difference(from: oldItems) { oldItem, newItem in
			oldItem.objectID == newItem.objectID
		}.inferringMoves()
		
		var indexesOfOldItemsToDelete = [Int]()
		var indexesOfNewItemsToInsert = [Int]()
		var indexesOfItemsToMove = [(oldIndex: Int, newIndex: Int)]()
		for change in difference {
			switch change {
			case .remove(let offset, _, let association):
				if let association = association {
					indexesOfItemsToMove.append((oldIndex: offset, newIndex: association))
				} else {
					indexesOfOldItemsToDelete.append(offset)
				}
			case .insert(let offset, _, let association):
				if association == nil {
					indexesOfNewItemsToInsert.append(offset)
				}
			}
		}
		
		return (
			indexesOfOldItemsToDelete,
			indexesOfNewItemsToInsert,
			indexesOfItemsToMove
		)
	}
	
}
