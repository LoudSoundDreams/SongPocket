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
			for currentIndex in items.indices { // The truth for the order of items is their order in this array, not the "index" attribute of each NSManagedObject, because the UI follows this array.
				items[currentIndex].setValue(Int64(currentIndex), forKey: "index") // Switch to proper type-checking
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
		if #available(iOS 15, *) { // See comment in the `else` block.
			/*
			 This is a rudimentary way of diffing two arrays to find the deletes, inserts, and moves. It's rudimentary, but it works. I shipped something similar in Songpocket 1.0.
			 For Songpocket 1.4, I replaced this with an implementation that uses CollectionDifference, but as of iPadOS 15 beta 2, array.difference(from:by:) is crashing with "Fatal error: unsupported". So I've brought this back, hopefully temporarily.
			 */
			
			var indexesOfItemsToMove = [(oldIndex: Int, newIndex: Int)]()
			var indexesOfNewItemsToInsert = [Int]()
			
			for indexOfNewItem in newItems.indices { // For each newItem
				let newItem = newItems[indexOfNewItem]
				if let indexOfMatchingOldItem = oldItems.firstIndex(where: { oldItem in
					oldItem.objectID == newItem.objectID
				}) {
					// Put the old and new indexes in the "moves" array.
					indexesOfItemsToMove.append(
						(oldIndex: indexOfMatchingOldItem, newIndex: indexOfNewItem)
					)
				} else {
					// Put the index in the "inserts" array.
					indexesOfNewItemsToInsert.append(indexOfNewItem)
				}
			}
			
			var indexesOfOldItemsToDelete = [Int]()
			
			for indexOfOldItem in oldItems.indices { // For each oldItem
				let oldItem = oldItems[indexOfOldItem]
				if let _ = newItems.firstIndex(where: { newItem in // If there's a corresponding newItem
					newItem.objectID == oldItem.objectID
				}) {
					continue
				} else {
					indexesOfOldItemsToDelete.append(indexOfOldItem)
				}
			}
			
			return (
				indexesOfOldItemsToDelete,
				indexesOfNewItemsToInsert,
				indexesOfItemsToMove
			)
			
		} else { // iOS 14 and earlier
			
			let difference = newItems.difference(from: oldItems) { oldItem, newItem in // As of iPadOS 15 beta 2, this crashes with "Fatal error: unsupported".
				oldItem.objectID == newItem.objectID
			}.inferringMoves()
			
			var indexesOfOldItemsToDelete = [Int]()
			var indexesOfNewItemsToInsert = [Int]()
			
			var indexesOfItemsToMove = [(oldIndex: Int, newIndex: Int)]()
			for change in difference {
				// If a Change's `associatedWith:` value is non-nil, then it has a counterpart Change in the CollectionDifference, and the two Changes together represent a move, rather than a remove and an insert.
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
	
}
