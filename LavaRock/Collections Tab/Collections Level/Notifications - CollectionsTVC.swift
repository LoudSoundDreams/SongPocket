//
//  Notifications - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-01.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// Remember: we might be in "moving albums" mode.
	
	
	// This is the same as in AlbumsTVC.
	/*
	func deleteFromViewWhileMovingAlbums(_ idsOfAllDeletedObjects: [NSManagedObjectID]) {
		guard let albumMoverClipboard = albumMoverClipboard else { return }
		
		for deletedID in idsOfAllDeletedObjects {
			if let indexOfDeletedAlbumID = albumMoverClipboard.idsOfAlbumsBeingMoved.firstIndex(where: { idOfAlbumBeingMoved in
				idOfAlbumBeingMoved == deletedID
			}) {
				albumMoverClipboard.idsOfAlbumsBeingMoved.remove(at: indexOfDeletedAlbumID)
				if albumMoverClipboard.idsOfAlbumsBeingMoved.count == 0 {
					dismiss(animated: true, completion: nil)
				}
			}
		}
		navigationItem.prompt = albumMoverClipboard.navigationItemPrompt // This needs to be separate from the code that modifies the array of albums being moved. Otherwise, another AlbumMover could be the one to modify that array, and only that AlbumMover would get an updated navigation item prompt.
	}
	*/
	
}
