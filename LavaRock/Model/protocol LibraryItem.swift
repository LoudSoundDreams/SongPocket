//
//  protocol LibraryItem.swift
//  LavaRock
//
//  Created by h on 2021-04-09.
//

import CoreData

protocol LibraryItem: NSManagedObject {
	var libraryTitle: String? { get }
	var index: Int64 { get set }
	
	func isInPlayer() -> Bool
}

protocol LibraryContainer: LibraryItem {
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
