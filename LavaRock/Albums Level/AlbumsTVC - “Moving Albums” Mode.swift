//
//  AlbumsTVC - “Moving Albums” Mode.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// MARK: - Ending Moving
	
	final func moveAlbumsHere() {
		
		guard
			let albumMoverClipboard = albumMoverClipboard,
			!albumMoverClipboard.didAlreadyCommitMoveAlbums // Without this, if you tap the "Move Here" button more than once, the app will crash.
				// You won't obviate this hack even if you put as much of this logic as possible onto a background queue to get to the animation sooner. The animation *is* the slow part. If I set a breakpoint before the animation, I can't even tap the "Move Here" button twice before hitting that breakpoint.
		else { return }
		
		albumMoverClipboard.didAlreadyCommitMoveAlbums = true
		
		// Get the Albums to move, and to not move.
		let albumsToMove = albumMoverClipboard.idsOfAlbumsBeingMoved.map { albumID in
			context.object(with: albumID) as! Album
		}
		var albumsToNotMove = albumMoverClipboard.idsOfAlbumsNotBeingMoved.map { albumID in
			context.object(with: albumID) as! Album
		}
		
		// Apply the changes.
		
		// Update the indexes of the Albums we aren't moving, within their Collection.
		albumsToNotMove.reindex()
		
		// Move the Albums we're moving.
		let destinationCollection = sectionOfLibraryItems.container as! Collection
		var newItems = sectionOfLibraryItems.items
		albumsToMove.reversed().forEach { album in
			album.container = destinationCollection
			// When we set sectionOfLibraryItems.items, the property observer will set the "index" attribute of each Album in this Collection for us.
			newItems.insert(album, at: 0)
		}
		// If we moved all the Albums out of the Collection they used to be in, then delete that Collection.
		Collection.deleteAllEmpty(context: context) // Note: This checks the contents of and reindexes destinationCollection, too.
		
		// Update the table view.
		setItemsAndRefresh(newItems: newItems) {
			self.context.tryToSave()
			self.context.parent!.tryToSave() // Save the main context now, even though we haven't exited editing mode, because if you moved all the Albums out of a Collection, we'll close the Collection and exit editing mode shortly.
			
			NotificationCenter.default.post(
				Notification(name: .LRDidMoveAlbums)
			)
			
			self.dismiss(animated: true)
			albumMoverClipboard.delegate?.didMoveAlbumsThenCommitDismiss()
		}
		
	}
	
}
