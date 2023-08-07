//
//  LibraryGroup.swift
//  LavaRock
//
//  Created by h on 2021-07-02.
//

import CoreData

protocol LibraryGroup {
	var container: NSManagedObject? { get }
	var items: [NSManagedObject] { get }
	mutating func setItems(_ newItems: [NSManagedObject])
	/*
	 Don’t let callers modify `items` directly; force them to use `setItems`. That encourages them to make atomic changes.
	 
	 Also, give `items` a property observer that sets the `index` attribute on each `NSManagedObject`, exactly like `[LibraryItem].reindex`:
	 //	didSet {
	 //		private_items.enumerated().forEach { (currentIndex, libraryItem) in
	 //			libraryItem.setValue(
	 //				Int64(currentIndex),
	 //				forKey: "index")
	 //		}
	 //	}
	 */
}
