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
		
		// Now we need to refresh our data and our views. But to do that, we won't pull the NSManagedObjectIDs out of this notification, because that's more logic for the same result. Instead we'll just re-fetch our data and see how we need to update our views.
		
		refreshDataWithAnimationWhenVisible()
		
		/*
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
		*/
		
		/*
		print("")
		print(idsOfObjectsToDeleteFromAnyView)
		print(idsOfItemsInThisViewToRefresh)
		*/
		
		/*
		deleteFromView(idsOfObjectsToDeleteFromAnyView)
		refreshInView(idsOfItemsInThisViewToRefresh)
		*/
	}
	
	func refreshDataWithAnimationWhenVisible() {
		if view.window == nil {
			shouldRefreshDataWithAnimationOnNextViewDidAppear = true
		} else {
			refreshDataWithAnimation()
		}
	}
	
	func refreshDataWithAnimation() {
		
		// Remember: in CollectionsTVC and AlbumsTVC, we might be in "moving albums" mode.
		
		/*
		TO DO:
		
		- Hack this for SongsTVC.
		- Hack this for CollectionsTVC and AlbumsTVC while moving albums.
		- Hack this for MoveAlbumsClipboard.
		- Refresh containerOfData.
		
		update the navigation item title
		
		*/
		
		print("")
		print(Self.self)
		print(String(describing: managedObjectContext.parent))
		
		let refreshedItems = managedObjectContext.objectsFetched(for: coreDataFetchRequest)
		
		let fixedSection = 0
		refreshRows(inSection: fixedSection, toMatch: refreshedItems)
		
		var startingAndEndingIndexPathsOfRowsToMove = [(IndexPath, IndexPath)]()
		var indexPathsOfNewItems = [IndexPath]()
		for indexOfRefreshedItem in 0 ..< refreshedItems.count {
			let refreshedItem = refreshedItems[indexOfRefreshedItem]
			if let indexOfOnscreenItem = activeLibraryItems.firstIndex(where: { onscreenItem in
				onscreenItem.objectID == refreshedItem.objectID
			}) { // This item is already onscreen, and we still want it onscreen. If necessary, we'll move it. Later, if necessary, we'll update it.
				let startingIndexPath = IndexPath(row: indexOfOnscreenItem, section: fixedSection)
				let endingIndexPath = IndexPath(row: indexOfRefreshedItem, section: fixedSection)
				startingAndEndingIndexPathsOfRowsToMove.append(
					(startingIndexPath, endingIndexPath)
				)
				
			} else { // This item isn't onscreen yet, but we want it onscreen, so we'll have to add it.
				indexPathsOfNewItems.append(IndexPath(row: indexOfRefreshedItem, section: fixedSection))
			}
		}
		
		var indexPathsOfRowsToDelete = [IndexPath]()
		for index in 0 ..< activeLibraryItems.count {
			let onscreenItem = activeLibraryItems[index]
			if let _ = refreshedItems.firstIndex(where: { refreshedItem in
				refreshedItem.objectID == onscreenItem.objectID
			})  {
				continue // to the next onscreenItem
			} else {
				indexPathsOfRowsToDelete.append(IndexPath(row: index, section: fixedSection))
			}
		}
		
		print("Deleting rows at: \(indexPathsOfRowsToDelete)")
		print("Inserting rows at: \(indexPathsOfNewItems)")
		print("Moving rows at: \(startingAndEndingIndexPathsOfRowsToMove)")
		
		activeLibraryItems = refreshedItems
		
		tableView.performBatchUpdates {
			tableView.deleteRows(at: indexPathsOfRowsToDelete, with: .middle)
			tableView.insertRows(at: indexPathsOfNewItems, with: .middle)
			for (startingIndexPath, endingIndexPath) in startingAndEndingIndexPathsOfRowsToMove {
				tableView.moveRow(at: startingIndexPath, to: endingIndexPath)
			}
		} completion: { _ in
			if self.activeLibraryItems.count == 0 {
				self.performSegue(withIdentifier: "Deleted All Contents", sender: self)
				return
			} else {
				print(self.containerOfData)
				
				
				self.refreshData()
			}
		}
		
	}
	
	func refreshRows(inSection section: Int, toMatch refreshedItems: [NSManagedObject]) {
		
		
		
	}
	
	
	/*
	This method is the final step in refreshDataWithAnimation(). The earlier steps delete, insert, and move rows as necessary (with animations), and update the data sources (including activeLibraryItems). This method's job is to update the data in those rows, which might be outdated: for example, songs' titles and albums' release date estimates.
	The simplest way to do this is to just call tableView.reloadData(). That's infamous for not animating the changes, but we actually animated the deletes, inserts, and moves by ourselves earlier. All we're doing here is updating the data within each row, which generally looks fine without an animation. (If you wanted to add an animation, the most reasonable choice would probably be a fade). With reloadData(), the overall animation for refreshDataWithAnimation() becomes "animate all the row movements, and the instant those movements end, instantly change the data in each row to reflect any updates"—which looks fine.
	You should override this method if you want to add an animation when you update any data. For example, if it looks jarring to change the album artwork in the songs view without an animation, you might want to refresh that artwork with a fade animation, and leave the rest of the views to update without animations.
	*/
	@objc func refreshData() {
		tableView.reloadData()
	}
	
	
	func didChangeAccentColor() {
		guard MPMediaLibrary.authorizationStatus() != .authorized else { return }
		tableView.reloadData()
	}
	
}
