//
//  SectionOfLibraryItems.swift
//  LavaRock
//
//  Created by h on 2021-03-04.
//

import CoreData
/*
protocol SectionOfLibraryItemsDelegate: AnyObject {
	func didSetItems()
}
*/
struct SectionOfLibraryItems {
	
	// MARK: - Properties
	
	// MARK: Constants
	
	let managedObjectContext: NSManagedObjectContext
	let container: NSManagedObject? // Switch to proper type-checking
	let entityName: String
	
//	// MARK: "Constants"
//
//	weak var delegate: SectionOfLibraryItemsDelegate?
	
	// MARK: Variables
	
	lazy var items = fetchedItems() {
		didSet {
			for index in 0 ..< items.count { // The truth for the order of items is their order in this array, not the "index" attribute of each NSManagedObject, because the UI follows this array.
				items[index].setValue(Int64(index), forKey: "index") // Switch to proper type-checking
			}
		}
	}
	
	// MARK: - Methods
	
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
		[Int],
		[Int],
		[(Int, Int)]
	) {
		let difference = newItems.difference(from: oldItems, by: { oldItem, newItem in
			oldItem.objectID == newItem.objectID
		}).inferringMoves()
		
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
	/*
	mutating func setItems(_ newItems: [NSManagedObject]) {
		let indexesOfChanges = Self.indexesOfDeletesInsertsAndMoves(
			oldItems: items,
			newItems: newItems)
		items = newItems
		delegate?.didSetItems()
	
	
	this will not work.
	1. didSetItem() triggers refreshDataAndViews(), which sets `items` again from fetchedItems().
	1a. we haven't saved our modified items via the managed object context in the first place
	2. refreshDataAndViews() wouldn't notice the right changes because it compares `items`to fetchedItems().
	}
	*/
}
