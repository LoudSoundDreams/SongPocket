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
//	var mpMediaItems = [NSManagedObjectID: MPMediaItem]()
	
	// MARK: - Methods
	
	init(
		managedObjectContext: NSManagedObjectContext,
		container: NSManagedObject?
	) {
		self.managedObjectContext = managedObjectContext
		self.container = container
		
		private_items = fetchedItems() // Doesn't trigger the property observer
		refreshShouldShowDiscNumbers()
//		refreshMPMediaItems()
	}
	
	private mutating func refreshShouldShowDiscNumbers() {
		let album = container as? Album
		let representativeItem = album?.mpMediaItemCollection()?.representativeItem
		let containsOnlyOneDisc = representativeItem?.discCount ?? 1 == 1
		let result = !containsOnlyOneDisc
		shouldShowDiscNumbers = result
	}
	
//	private mutating func refreshMPMediaItems() {
//		mpMediaItems.removeAll() //
//
//
//		let keyValuePairs: [(NSManagedObjectID, MPMediaItem)] = items.compactMap {
//			guard let mpMediaItem = ($0 as? Song)?.mpMediaItem() else { // SHOW-STOPPER: MPMediaItem properties are outdated
//				return nil
//			}
//			print("")
//			print(String(describing: mpMediaItem.title))
//			print(String(describing: mpMediaItem.albumArtist))
//			print(String(describing: mpMediaItem.artist))
//			return ($0.objectID, mpMediaItem)
//		}
//		let newDictionary = Dictionary(uniqueKeysWithValues: keyValuePairs)
//		mpMediaItems = newDictionary
//	}
	
//	func mpMediaItemFast(for song: NSManagedObject) -> MPMediaItem? {
//		if let cachedMPMediaItem = mpMediaItems[song.objectID] {
//			return cachedMPMediaItem
//		} else {
//			return (song as? Song)?.mpMediaItem()
//		}
//	}
//
//	func mpMediaItemsCompactFast(for songs: [NSManagedObject]) -> [MPMediaItem] {
//		return songs.compactMap {
//			mpMediaItemFast(for: $0)
//		}
//	}
	
	// MARK: - SectionOfLibraryItems
	
	// Constants
	let entityName = "Song"
	let managedObjectContext: NSManagedObjectContext
	let container: NSManagedObject?
	
	// Variables
	var items: [NSManagedObject] { private_items }
	private var private_items = [NSManagedObject]() {
		didSet {
			for currentIndex in private_items.indices {
				private_items[currentIndex].setValue(Int64(currentIndex), forKey: "index")
			}
			
			print(private_items.count)
			refreshShouldShowDiscNumbers()
//			refreshMPMediaItems()
		}
	}
	
	mutating func setItems(_ newItems: [NSManagedObject]) {
		private_items = newItems
	}
	
}
