//
//  Notifications (AlbumsTVC).swift
//  LavaRock
//
//  Created by h on 2020-09-03.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// Remember: we might be in "moving albums" mode.
	
	// This is the same as in CollectionsTVC.
	override func beginObservingNotifications() {
		super.beginObservingNotifications()
		
		if moveAlbumsClipboard != nil {
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(didObserve(_:)),
				name: Notification.Name.NSManagedObjectContextDidSaveObjectIDs,
				object: managedObjectContext.parent)
		}
	}
	
	// This is the same as in CollectionsTVC.
	override func deleteFromView(_ idsOfAllDeletedObjects: [NSManagedObjectID]) {
		super.deleteFromView(idsOfAllDeletedObjects)
		
		if let moveAlbumsClipboard = moveAlbumsClipboard {
			for deletedID in idsOfAllDeletedObjects {
				if let indexOfDeletedAlbumID = moveAlbumsClipboard.idsOfAlbumsBeingMoved.firstIndex(where: { idOfAlbumBeingMoved in
					idOfAlbumBeingMoved == deletedID
				}) {
					moveAlbumsClipboard.idsOfAlbumsBeingMoved.remove(at: indexOfDeletedAlbumID)
					if moveAlbumsClipboard.idsOfAlbumsBeingMoved.count == 0 {
						dismiss(animated: true, completion: nil)
					}
				}
			}
			navigationItem.prompt = moveAlbumsClipboard.navigationItemPrompt // This needs to be separate from the code that modifies the array of albums being moved. Otherwise, another AlbumMover could be the one to modify that array, and only that AlbumMover would get an updated navigation item prompt.
		}
	}
	
	
	
}
