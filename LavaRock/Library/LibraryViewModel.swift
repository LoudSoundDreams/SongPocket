//
//  LibraryViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-12.
//

import CoreData

typealias ColumnOfLibraryItems = [LibraryGroup]
protocol LibraryViewModel {
	static var entityName: String { get }
	
	var context: NSManagedObjectContext { get }
	var prerowCount: Int { get }
	
	var groups: ColumnOfLibraryItems { get set }
	
	func prerowIdentifiers() -> [AnyHashable]
	func updatedWithFreshenedData() -> Self
}

struct SectionStructure<
	Identifier: Hashable,
	RowIdentifier: Hashable
> {
	let identifier: Identifier
	let rowIdentifiers: [RowIdentifier]
}
extension SectionStructure: Hashable {}
enum SectionID: Hashable {
	case groupWithNoContainer
	case groupWithContainer(NSManagedObjectID)
}
enum RowID: Hashable {
	case prerow(AnyHashable)
	case libraryItem(NSManagedObjectID)
}

extension LibraryViewModel {
	func isEmpty() -> Bool {
		return groups.allSatisfy { group in
			group.items.isEmpty
		}
	}
	
	func sectionStructures() -> [SectionStructure<SectionID, RowID>] {
		return groups.map { group in
			let sectionID: SectionID = {
				guard let containerID = group.container?.objectID else {
					return .groupWithNoContainer
				}
				return .groupWithContainer(containerID)
			}()
			
			let prerowIDs = prerowIdentifiers().map {
				RowID.prerow($0)
			}
			let itemRowIDs = group.items.map { item in
				RowID.libraryItem(item.objectID)
			}
			let rowIDs = prerowIDs + itemRowIDs
			
			return SectionStructure(
				identifier: sectionID,
				rowIdentifiers: rowIDs)
		}
	}
	
	// MARK: - Elements
	
	func libraryGroup() -> LibraryGroup {
		return groups[0]
	}
	
	func pointsToSomeItem(row: Int) -> Bool {
		guard !isEmpty() else {
			return false
		}
		let items = libraryGroup().items
		let itemIndex = itemIndex(forRow: row)
		guard 0 <= itemIndex, itemIndex < items.count else {
			return false
		}
		return true
	}
	
	func itemNonNil(atRow: Int) -> NSManagedObject {
		let itemIndex = itemIndex(forRow: atRow)
		return libraryGroup().items[itemIndex]
	}
	
	func itemIndex(forRow row: Int) -> Int {
		return row - prerowCount
	}
	
	func rowsForAllItems() -> [Int] {
		guard !isEmpty() else {
			return []
		}
		let indices = libraryGroup().items.indices
		return indices.map {
			prerowCount + $0
		}
	}
	func row(forItemIndex itemIndex: Int) -> Int {
		return prerowCount + itemIndex
	}
	
	// MARK: - Editing
	
	mutating func moveItem(atRow: Int, toRow: Int) {
		let atIndex = itemIndex(forRow: atRow)
		let toIndex = itemIndex(forRow: toRow)
		
		var newItems = libraryGroup().items
		let itemBeingMoved = newItems.remove(at: atIndex)
		newItems.insert(itemBeingMoved, at: toIndex)
		groups[0].setItems(newItems)
	}
}
