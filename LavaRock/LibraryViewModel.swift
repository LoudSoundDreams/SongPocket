//
//  LibraryViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-12.
//

import CoreData

typealias ColumnOfLibraryItems = [LibraryGroup]
protocol LibraryViewModel {
	var context: NSManagedObjectContext { get }
	var groups: ColumnOfLibraryItems { get set }
	
	func prerowCount() -> Int
	func prerowIdentifiers() -> [AnyHashable]
	func updatedWithFreshenedData() -> Self
}
extension LibraryViewModel {
	func isEmpty() -> Bool {
		return groups.allSatisfy { group in
			group.items.isEmpty
		}
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
	
	func libraryGroup() -> LibraryGroup {
		return groups[0]
	}
	func itemNonNil(atRow: Int) -> NSManagedObject {
		let itemIndex = itemIndex(forRow: atRow)
		return libraryGroup().items[itemIndex]
	}
	
	func itemIndex(forRow row: Int) -> Int {
		return row - prerowCount()
	}
	
	func rowsForAllItems() -> [Int] {
		guard !isEmpty() else {
			return []
		}
		let indices = libraryGroup().items.indices
		return indices.map {
			prerowCount() + $0
		}
	}
	func row(forItemIndex itemIndex: Int) -> Int {
		return prerowCount() + itemIndex
	}
}

struct SectionStructure<RowIdentifier: Hashable> {
	let rowIdentifiers: [RowIdentifier]
}
extension SectionStructure: Hashable {}
enum RowID: Hashable {
	case prerow(AnyHashable)
	case libraryItem(NSManagedObjectID)
}
extension LibraryViewModel {
	func sectionStructure() -> SectionStructure<RowID> {
		let prerowIDs = prerowIdentifiers().map {
			RowID.prerow($0)
		}
		let itemRowIDs = groups[0].items.map { item in
			RowID.libraryItem(item.objectID)
		}
		let rowIDs = prerowIDs + itemRowIDs
		
		return SectionStructure(rowIdentifiers: rowIDs)
	}
}
