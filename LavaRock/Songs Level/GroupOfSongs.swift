//
//  GroupOfSongs.swift
//  LavaRock
//
//  Created by h on 2021-07-02.
//

import CoreData
import MediaPlayer

struct GroupOfSongs: GroupOfLibraryItems {
	
	// MARK: - GroupOfLibraryItems
	
	// Constants
	let container: NSManagedObject?
	
	// Variables
	var items: [NSManagedObject] { private_items }
	private var private_items = [NSManagedObject]() {
		didSet {
			private_items.indices.forEach { currentIndex in
				private_items[currentIndex].setValue(
					Int64(currentIndex),
					forKey: "Index")
			}
			
			refreshShouldShowDiscNumbers()
		}
	}
	
	mutating func setItems(_ newItems: [NSManagedObject]) {
		private_items = newItems
	}
	
	// MARK: - Miscellaneous
	
	var shouldShowDiscNumbers = false
	
	init(
		entityName: String,
		container: NSManagedObject?,
		context: NSManagedObjectContext
	) {
		self.container = container
		
		private_items = itemsFetched( // Doesn't trigger the property observer
			entityName: entityName,
			context: context)
		refreshShouldShowDiscNumbers()
	}
	
	private mutating func refreshShouldShowDiscNumbers() {
		let album = container as? Album
		let representativeItem = album?.mpMediaItemCollection()?.representativeItem
		let containsOnlyOneDisc = representativeItem?.discCount ?? 1 == 1
		let result = !containsOnlyOneDisc
		shouldShowDiscNumbers = result
	}
	
}
