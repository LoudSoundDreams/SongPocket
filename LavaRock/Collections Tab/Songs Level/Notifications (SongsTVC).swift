//
//  Notifications (SongsTVC).swift
//  LavaRock
//
//  Created by h on 2020-09-02.
//

import UIKit
import CoreData

extension SongsTVC {
	
	override func deleteFromView(_ allObjectsDeletedDuringPreviousMerge: [NSManagedObject]) {
		if
			let containerOfData = containerOfData,
			allObjectsDeletedDuringPreviousMerge.contains(containerOfData)
		{
			performSegue(withIdentifier: "Deleted All Songs", sender: self)
			
		} else {
			
			var indexesInActiveLibraryItemsToDelete = [Int]()
			for songToDelete in allObjectsDeletedDuringPreviousMerge {
				if let indexInActiveLibraryItems = activeLibraryItems.lastIndex(where: { activeSong in // Use .lastIndex(where:), not .firstIndex(where:), because in this class, we've hacked activeLibraryItems by inserting dummy duplicate songs at the beginning.
					activeSong.objectID == songToDelete.objectID
				}) {
					indexesInActiveLibraryItemsToDelete.append(indexInActiveLibraryItems)
				}
			}
			var indexPathsToDelete = [IndexPath]()
			for index in indexesInActiveLibraryItemsToDelete {
				indexPathsToDelete.append(IndexPath(row: index, section: 0))
				activeLibraryItems.remove(at: index)
			}
			tableView.performBatchUpdates({
				tableView.deleteRows(
					at: indexPathsToDelete,
					with: .middle)
			}, completion: nil)
			if activeLibraryItems.count == numberOfUneditableRowsAtTopOfSection { // If activeLibraryItems contains nothing but the dummy items; all the songs have been deleted from this album.
				// Control flow should never actually reach here, because if all the songs within this album were deleted, then the album would have been deleted during the merge too, and we would have taught that at the beginning of this method.
				performSegue(withIdentifier: "Deleted All Songs", sender: self)
			} else {
				refreshDummyDuplicatesInActiveLibraryItems()
			}
			
		}
	}
	
	// Clean up the dummy songs at the beginning of activeLibraryItems: make sure they're duplicates of songs that still exist, so that we don't confuse ourselves by having songs in activeLibraryItems that don't exist in the persistent store anymore.
	func refreshDummyDuplicatesInActiveLibraryItems() {
		for index in 0 ..< numberOfUneditableRowsAtTopOfSection {
			activeLibraryItems[index] = activeLibraryItems[numberOfUneditableRowsAtTopOfSection]
		}
	}
	
//	override func refreshInView(_ items: [NSManagedObject]) {
//		print("")
//		for item in items {
//			let song = item as! Song
//			print("We need to refresh the song \(song.titleFormattedOrPlaceholder()) in this view.")
//		}
//	}
	
}
