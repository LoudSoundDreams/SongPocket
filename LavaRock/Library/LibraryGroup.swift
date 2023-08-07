//
//  LibraryGroup.swift
//  LavaRock
//
//  Created by h on 2021-07-02.
//

import CoreData

protocol LibraryGroup {
	var container: NSManagedObject? { get }
	var items: [NSManagedObject] { get set } // You must add a `didSet` that calls `_reindex()`.
}
extension LibraryGroup {
	// Must match `[LibraryItem].reindex`.
	func _reindex() {
		items.enumerated().forEach { (currentIndex, libraryItem) in
			libraryItem.setValue(
				Int64(currentIndex),
				forKey: "index")
		}
	}
}
