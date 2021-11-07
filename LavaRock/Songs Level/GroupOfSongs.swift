//
//  GroupOfSongs.swift
//  LavaRock
//
//  Created by h on 2021-07-02.
//

import CoreData
import MediaPlayer

extension GroupOfSongs: Hashable {
	// Enables `[GroupOfSongs].difference(from:by:)`
}

struct GroupOfSongs: GroupOfLibraryItems {
	
	// MARK: - GroupOfLibraryItems
	
	let container: NSManagedObject?
	
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
		let discCount = representativeItem?.discCount
		let containsOnlyOneDisc = discCount == 1 || discCount == nil || discCount == 0 // As of iOS 15.0 RC, MediaPlayer sometimes reports discCount as 0 for albums with 1 disc.
		shouldShowDiscNumbers = !containsOnlyOneDisc
	}
	
}
