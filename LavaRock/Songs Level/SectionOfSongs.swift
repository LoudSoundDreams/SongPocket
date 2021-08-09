//
//  SectionOfSongs.swift
//  LavaRock
//
//  Created by h on 2021-07-02.
//

import CoreData
import MediaPlayer

struct SectionOfSongs: SectionOfLibraryItems {
	
	// MARK: - Properties
	
	// Variables
	var shouldShowDiscNumbers = false
	
	// MARK: - Methods
	
	init(
		container: NSManagedObject?,
		context: NSManagedObjectContext
	) {
		self.container = container
		
		private_items = itemsFetched(context: context) // Doesn't trigger the property observer
		refreshShouldShowDiscNumbers()
	}
	
	private mutating func refreshShouldShowDiscNumbers() {
		let album = container as? Album
		let representativeItem = album?.mpMediaItemCollection()?.representativeItem
		let containsOnlyOneDisc = representativeItem?.discCount ?? 1 == 1
		let result = !containsOnlyOneDisc
		shouldShowDiscNumbers = result
	}
	
	// MARK: - SectionOfLibraryItems
	
	// Constants
	let entityName = "Song"
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
	
}
