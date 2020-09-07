//
//  Notifications (CollectionsTVC).swift
//  LavaRock
//
//  Created by h on 2020-09-01.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// Remember: we might be in "moving albums" mode.
	
	// This is the same as in AlbumsTVC.
	override func beginObservingNotifications() {
		super.beginObservingNotifications()
		
		if moveAlbumsClipboard != nil {
			beginObservingAlbumMoverNotifications()
		}
	}
	
	// This is the same as in AlbumsTVC.
	func beginObservingAlbumMoverNotifications() {
		guard moveAlbumsClipboard != nil else { return }
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.NSManagedObjectContextDidMergeChangesObjectIDs,
			object: managedObjectContext)
	}
	
	// This is the same as in AlbumsTVC.
	override func didObserve(_ notification: Notification) {
		switch notification.name {
		case .NSManagedObjectContextDidMergeChangesObjectIDs:
			mocDidMergeChanges()
			return
		default: break
		}
		
		super.didObserve(notification)
	}
	
	// This is the same as in AlbumsTVC.
	override func willSaveChangesFromAppleMusicLibrary() {
		if moveAlbumsClipboard != nil {
			guard respondsToWillSaveChangesFromAppleMusicLibraryNotifications else { return }
			shouldRespondToNextMOCDidMergeChangesNotification = true
		} else {
			super.willSaveChangesFromAppleMusicLibrary()
		}
	}
	
	// This is the same as in AlbumsTVC.
	// This is the counterpart to mocDidSave() when not moving albums.
	func mocDidMergeChanges() {
		// We shouldn't respond to all of these notifications. For example, after tapping "Move Here", we move albums into a collection and save the main context, which triggers an NSManagedObjectContextDidMergeChangesObjectIDs notification, and the entire chain starting here can get all the way to refreshTableViewRowContents(), which is just tableView.reloadData() by default, which interrupts the animation inserting the albums into the collection.
		guard
			moveAlbumsClipboard != nil,
			shouldRespondToNextMOCDidMergeChangesNotification
		else { return }
		shouldRespondToNextMOCDidMergeChangesNotification = false
		refreshDataAndViewsWhenVisible()
	}
	
	
	
	// This is the same as in AlbumsTVC.
	/*
	func deleteFromViewWhileMovingAlbums(_ idsOfAllDeletedObjects: [NSManagedObjectID]) {
		guard let moveAlbumsClipboard = moveAlbumsClipboard else { return }
		
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
	*/
	
	
	
}
