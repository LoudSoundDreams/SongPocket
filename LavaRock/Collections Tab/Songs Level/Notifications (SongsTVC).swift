//
//  Notifications (SongsTVC).swift
//  LavaRock
//
//  Created by h on 2020-09-02.
//

import UIKit
import CoreData

extension SongsTVC {
	
	override func deleteFromView(_ idsOfAllDeletedObjects: [NSManagedObjectID]) {
		super.deleteFromView(idsOfAllDeletedObjects)
		
		refreshDummyDuplicatesInActiveLibraryItems()
	}
	
	// Clean up the dummy songs at the beginning of activeLibraryItems: make sure they're duplicates of songs that still exist, so that we don't confuse ourselves by having songs in activeLibraryItems that don't exist in the persistent store anymore.
	func refreshDummyDuplicatesInActiveLibraryItems() {
		for index in 0 ..< numberOfUneditableRowsAtTopOfSection {
			activeLibraryItems[index] = activeLibraryItems[numberOfUneditableRowsAtTopOfSection]
		}
	}
	
//	override func refreshInView(_ itemsInThisView: [NSManagedObject]) {
//		print("")
//		for item in items {
//			let song = item as! Song
//			print("We need to refresh the song \(song.titleFormattedOrPlaceholder()) in this view.")
//		}
//	}
	
}
