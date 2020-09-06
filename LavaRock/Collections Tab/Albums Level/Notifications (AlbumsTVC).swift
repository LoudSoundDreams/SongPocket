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
		
		beginObservingAlbumMoverNotifications()
	}
	
	// This is the same as in CollectionsTVC.
	func beginObservingAlbumMoverNotifications() {
		guard moveAlbumsClipboard != nil else { return }
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.NSManagedObjectContextDidSaveObjectIDs,
			object: managedObjectContext.parent)
		
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.NSManagedObjectContextDidMergeChangesObjectIDs,
			object: managedObjectContext)
		
		
	}
	
	
	override func didObserve(_ notification: Notification) {
		super.didObserve(notification)
		
		switch notification.name {
		case .NSManagedObjectContextDidMergeChangesObjectIDs:
			print(notification)
			break
		default: break
		}
	}
	
	/*
	override func refreshOutdatedViews() {
		for section in 0 ..< tableView.numberOfSections {
			for row in 0 ..< tableView.numberOfRows(inSection: section) {
				let indexPath = IndexPath(row: row, section: section)
				if let onscreenCell = tableView.cellForRow(at: indexPath) as? AlbumCell { // This returns an existing cell, not a new cell.
					let onscreenArtworkImage = onscreenCell.artworkImageView.image
					let onscreenTitleText = onscreenCell.titleLabel.text
					let onscreenReleaseDateText = onscreenCell.releaseDateLabel.text
					print(String(describing: onscreenArtworkImage))
					print(String(describing: onscreenTitleText))
					print(String(describing: onscreenReleaseDateText))
					
					let refreshedCell = tableView(tableView, cellForRowAt: indexPath) as! AlbumCell
					let refreshedArtworkImage = refreshedCell.artworkImageView.image
					let refreshedTitleText = refreshedCell.titleLabel.text
					let refreshedReleaseDateText = refreshedCell.releaseDateLabel.text
					print(String(describing: refreshedArtworkImage))
					print(String(describing: refreshedTitleText))
					print(String(describing: refreshedReleaseDateText))
					
					let isOnscreenCellOutdated =
						(onscreenArtworkImage != refreshedArtworkImage) ||
						(onscreenTitleText != refreshedTitleText) ||
						(onscreenReleaseDateText != refreshedReleaseDateText)
					print(isOnscreenCellOutdated)
					if isOnscreenCellOutdated {
						tableView.reloadRows(at: [indexPath], with: .none)
					}
					
				}
				
			}
		}
	}
	*/
	
	
	// This is the same as in CollectionsTVC.
	/*
	override func deleteFromView(_ idsOfAllDeletedObjects: [NSManagedObjectID]) {
		super.deleteFromView(idsOfAllDeletedObjects)
		
		deleteFromViewWhileMovingAlbums(idsOfAllDeletedObjects)
	}
	*/
	
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
	
	
	
}
