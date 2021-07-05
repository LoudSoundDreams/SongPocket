//
//  AlbumsTVC - “Moving Albums” Mode.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// MARK: - Ending Moving Albums
	
	@objc final func moveAlbumsHere() {
		
		guard
			let albumMoverClipboard = albumMoverClipboard,
			!albumMoverClipboard.didAlreadyCommitMoveAlbums
		else { return }
		
		// We shouldn't be moving Albums to this Collection if they're already here.
		for albumInCollectionToMoveTo in sectionOfLibraryItems.items {
			if albumMoverClipboard.idsOfAlbumsBeingMoved.contains(albumInCollectionToMoveTo.objectID) {
				return
			}
		}
		
		albumMoverClipboard.didAlreadyCommitMoveAlbums = true // Without this, if you tap the "Move Here" button more than once, the app will crash.
		// You won't obviate this hack even if you put as much of this logic as possible onto a background queue to get to the animation sooner. The animation *is* the slow part. If I set a breakpoint before the animation, I can't even tap the "Move Here" button twice before hitting that breakpoint.
		
		// Get the Albums to move, and to not move.
		let albumsToMove = albumMoverClipboard.idsOfAlbumsBeingMoved.map { albumID in
			managedObjectContext.object(with: albumID) as! Album
		}
		var albumsToNotMove = albumMoverClipboard.idsOfAlbumsNotBeingMoved.map { albumID in
			managedObjectContext.object(with: albumID) as! Album
		}
		
		// Apply the changes.
		
		// Update the indexes of the Albums we aren't moving, within their Collection.
		albumsToNotMove.reindex()
		
		// Move the Albums we're moving.
		let destinationCollection = sectionOfLibraryItems.container as! Collection
		var newItems = sectionOfLibraryItems.items
		for album in albumsToMove.reversed() {
			album.container = destinationCollection
			// When we set sectionOfLibraryItems.items, the property observer will set the "index" attribute of each Album in this Collection for us.
			newItems.insert(album, at: 0)
		}
		// If we moved all the Albums out of the Collection they used to be in, then delete that Collection.
		Collection.deleteAllEmpty(via: managedObjectContext) // Note: This checks the contents of and reindexes destinationCollection, too.
		
		// Update the table view.
		setItemsAndRefreshTableView(newItems: newItems) {
			self.managedObjectContext.tryToSaveSynchronously()
			guard let mainManagedObjectContext = self.managedObjectContext.parent else {
				fatalError("After the user tapped “Move Here”, we couldn’t access the main managed object context to save changes.")
			}
			mainManagedObjectContext.tryToSaveSynchronously()
			
			self.dismiss(animated: true, completion: { albumMoverClipboard.delegate?.didMoveAlbumsThenFinishDismiss()
			})
			albumMoverClipboard.delegate?.didMoveAlbumsThenCommitDismiss()
		}
		
	}
	
}
