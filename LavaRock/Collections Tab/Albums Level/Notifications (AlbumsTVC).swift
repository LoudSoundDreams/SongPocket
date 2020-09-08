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
		
		if albumMoverClipboard != nil {
			beginObservingAlbumMoverNotifications()
		}
	}
	
	// This is the same as in CollectionsTVC.
	func beginObservingAlbumMoverNotifications() {
		guard albumMoverClipboard != nil else { return }
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.NSManagedObjectContextDidMergeChangesObjectIDs,
			object: managedObjectContext)
	}
	
	// This is the same as in CollectionsTVC.
	override func didObserve(_ notification: Notification) {
		switch notification.name {
		case .NSManagedObjectContextDidMergeChangesObjectIDs:
			managedObjectContextDidMergeChanges()
			return
		default: break
		}
		
		super.didObserve(notification)
	}
	
	// This is the same as in CollectionsTVC.
	override func willSaveChangesFromAppleMusicLibrary() {
		if albumMoverClipboard != nil {
			guard respondsToWillSaveChangesFromAppleMusicLibraryNotifications else { return }
			shouldRespondToNextMOCDidMergeChangesNotification = true
		} else {
			super.willSaveChangesFromAppleMusicLibrary()
		}
	}
	
	// This is the same as in CollectionsTVC.
	// This is the counterpart to managedObjectContextDidSave() when not moving albums.
	func managedObjectContextDidMergeChanges() {
		// We shouldn't respond to all of these notifications. For example, after tapping "Move Here", we move albums into a collection and save the main context, which triggers an NSManagedObjectContextDidMergeChangesObjectIDs notification, and the entire chain starting here can get all the way to refreshTableViewRowContents(), which is just tableView.reloadData() by default, which interrupts the animation inserting the albums into the collection.
		guard
			albumMoverClipboard != nil,
			shouldRespondToNextMOCDidMergeChangesNotification
		else { return }
		shouldRespondToNextMOCDidMergeChangesNotification = false
		refreshDataAndViewsWhenVisible()
	}
	
	
	
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
	
	
	
}
