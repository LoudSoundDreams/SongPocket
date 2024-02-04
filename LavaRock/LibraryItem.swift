//
//  LibraryItem.swift
//  LavaRock
//
//  Created by h on 2021-04-09.
//

import CoreData

protocol LibraryContainer: NSManagedObject {
	var contents: NSSet? { get }
}
extension LibraryContainer {
	func isEmpty() -> Bool {
		return contents == nil || contents?.count == 0
	}
	
	func wasDeleted() -> Bool {
		return managedObjectContext == nil
	}
}

protocol LibraryItem: NSManagedObject {
	var index: Int64 { get set }
	
	func containsPlayhead() -> Bool
}

extension Array where Element: LibraryItem {
	// Needs to match the property observer on `LibraryGroup.items`.
	mutating func reindex() {
		enumerated().forEach { (currentIndex, libraryItem) in
			libraryItem.index = Int64(currentIndex)
		}
	}
}
