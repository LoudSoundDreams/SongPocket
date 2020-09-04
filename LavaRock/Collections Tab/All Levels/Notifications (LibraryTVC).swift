//
//  Notifications (LibraryTVC).swift
//  LavaRock
//
//  Created by h on 2020-08-29.
//

import UIKit
import MediaPlayer
import CoreData

extension LibraryTVC {
	
	// MARK: - Setup and Teardown
	
	@objc func beginObservingNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.LRWillSaveChangesFromAppleMusicLibrary,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.NSManagedObjectContextDidSaveObjectIDs,
			object: managedObjectContext)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.LRDidChangeAccentColor,
			object: nil)
	}
	
	func endObservingNotifications() {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Responding
	
	@objc func didObserve(_ notification: Notification) {
		switch notification.name {
		case .LRWillSaveChangesFromAppleMusicLibrary:
			willSaveChangesFromAppleMusicLibrary()
		case .NSManagedObjectContextDidSaveObjectIDs:
			managedObjectContextDidSaveObjectIDs(notification)
		case .LRDidChangeAccentColor:
			didChangeAccentColor()
		default:
			print("An instance of \(Self.self) observed the notification: \(notification.name)")
			print("… but the app is not set to do anything after observing that notification.")
		}
	}
	
	private func willSaveChangesFromAppleMusicLibrary() {
		guard respondsToWillSaveChangesFromAppleMusicLibraryNotifications else { return }
		shouldRespondToNextManagedObjectContextDidSaveObjectIDsNotification = true
	}
	
	@objc func managedObjectContextDidSaveObjectIDs(_ notification: Notification) {
		guard shouldRespondToNextManagedObjectContextDidSaveObjectIDsNotification else { return }
		shouldRespondToNextManagedObjectContextDidSaveObjectIDsNotification = false
		
		/*
		print("")
		print(Self.self)
		print(managedObjectContext.parent)
		*/
		
		// Remember: this method gets called in every subclass of LibraryTVC. And in CollectionsTVC and AlbumsTVC, we might be in "moving albums" mode.
		
		var idsOfObjectsToDeleteFromAnyView = [NSManagedObjectID]()
		var idsOfItemsInThisViewToRefresh = [NSManagedObjectID]()
		
		for key in [NSDeletedObjectIDsKey, NSInsertedObjectIDsKey, NSUpdatedObjectIDsKey] {
			guard let idsOfChangedObjects = notification.userInfo?[key] as? Set<NSManagedObjectID> else {
				continue // to the next key
			}
			
			guard key != NSDeletedObjectIDsKey else {
				idsOfObjectsToDeleteFromAnyView.append(contentsOf: idsOfChangedObjects)
				continue // to the next key
			}
			
			// key is NSInsertedObjectIDsKey or NSUpdatedObjectIDsKey.
			for objectID in idsOfChangedObjects {
				guard objectID.entity.name == coreDataEntityName else {
					continue // to the next object
				}
				
				var isObjectInThisView = false
				for item in activeLibraryItems {
					if item.objectID == objectID {
						isObjectInThisView = true
					}
				}
				if containerOfData == nil || isObjectInThisView {
					idsOfItemsInThisViewToRefresh.append(objectID)
				}
			}
		}
		
		/*
		print("")
		print(idsOfObjectsToDeleteFromAnyView)
		print(idsOfItemsInThisViewToRefresh)
		*/
		
		deleteFromView(idsOfObjectsToDeleteFromAnyView)
		refreshInView(idsOfItemsInThisViewToRefresh)
	}
	
	// objects will contain all the collections, albums, and songs that were deleted in the last merge; i.e., all the NSManagedObjects, of any entity, not just the ones relevant to any one view.
	@objc func deleteFromView(_ idsOfAllDeletedObjects: [NSManagedObjectID]) {
		
		// Remember: for CollectionsTVC and AlbumsTVC, we might be in "moving albums" mode.
		
		if
			let containerOfData = containerOfData,
			idsOfAllDeletedObjects.contains(containerOfData.objectID)
		{
			performSegue(withIdentifier: "Deleted All Contents", sender: self)
			
		} else {
			
			var indexesInActiveLibraryItemsToDelete = [Int]()
			for idToDelete in idsOfAllDeletedObjects {
				if let indexInActiveLibraryItems = activeLibraryItems.lastIndex(where: { activeItem in // Use .lastIndex(where:), not .firstIndex(where:), because SongsTVC hacks activeLibraryItems by inserting dummy duplicate songs at the beginning.
					activeItem.objectID == idToDelete
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
			
		}
	
	}
	
	@objc func refreshInView(_ idsOfItemsInThisView: [NSManagedObjectID]) {
		print("The class “\(Self.self)” should override refreshInView(_:). We would call it at this point.")
	}
	
	func didChangeAccentColor() {
		guard MPMediaLibrary.authorizationStatus() != .authorized else { return }
		tableView.reloadData()
	}
	
}
