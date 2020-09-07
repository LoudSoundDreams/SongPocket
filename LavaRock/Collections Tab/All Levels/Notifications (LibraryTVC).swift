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
			mocDidSave()
		case .LRDidChangeAccentColor:
			didChangeAccentColor()
		default:
			print("An instance of \(Self.self) observed the notification: \(notification.name)")
			print("… but the app is not set to do anything after observing that notification.")
		}
	}
	
	// Override this to change how this class responds to changes from the Apple Music library. Usually (i.e., for the base view controllers, not in "moving albums" mode), the right response is to wait for the next NSManagedObjectContextDidSaveObjectIDs notification and refresh our data and views after that.
	// When in "moving albums" mode, since the managed object context will be a child of the main one, we should instead wait for the next NSManagedObjectContextDidMergeChangeObjectIDs notification and refresh our data and views after that.
	@objc func willSaveChangesFromAppleMusicLibrary() {
		guard respondsToWillSaveChangesFromAppleMusicLibraryNotifications else { return }
		shouldRespondToNextMOCDidSaveObjectIDsNotification = true
	}
	
	func mocDidSave() {
		// We shouldn't respond to all of these notifications. For example, we don't need to do anything after exiting edit mode, which saves the context.
		guard shouldRespondToNextMOCDidSaveObjectIDsNotification else { return }
		shouldRespondToNextMOCDidSaveObjectIDsNotification = false
		
		// Now we need to refresh our data and our views. But to do that, we won't pull the NSManagedObjectIDs out of this notification, because that's more logic for the same result. Instead, we'll just re-fetch our data and see how we need to update our views.
		
		refreshDataAndViewsWhenVisible()
	}
	
	func refreshDataAndViewsWhenVisible() {
		if view.window == nil {
			shouldRefreshDataAndViewsOnNextViewDidAppear = true
		} else {
			refreshDataAndViews()
		}
	}
	
	func refreshDataAndViews() {
		
		print("")
		print(Self.self)
		print(String(describing: managedObjectContext.parent))
		
		/*
		TO DO:
		- Make this work in AlbumsTVC in "moving albums" mode.
		- Make this work in CollectionsTVC in "moving albums" mode.
			- Use numberOfRowsAboveIndexedLibraryItems to rewrite making new collections.
		- What if we're moving albums, and the collection we're moving those albums out of gets modified?
		- What if we're moving albums, and those albums get deleted (or modified any other way) by the merger?
		- Refresh containerOfData (it's a piece of data) and all the views it affects, including the navigation item title.
		*/
		
		let refreshedItems = managedObjectContext.objectsFetched(for: coreDataFetchRequest)
		refreshTableView(
			section: 0,
			onscreenItems: indexedLibraryItems,
			refreshedItems: refreshedItems)
		
		
	}
	
	// Easy to plug arguments into. You can call this on its own, separate from refreshDataAndViews().
	// Note: Even though this method is easy to plug arguments into, it (currently) has side effects: it replaces indexedLibraryItems with the onscreenItems array that you pass in.
	func refreshTableView(
		section: Int,
		onscreenItems: [NSManagedObject],
		refreshedItems: [NSManagedObject]
	) {
		
		guard refreshedItems.count >= 1 else {
			let allIndexPathsInSection = indexPathsEnumeratedIn(
				section: section,
				firstRow: 0, // For SongsTVC, it could look nice to only delete the song cells (below the album artwork and album info cells), but that would add another state we need to accommodate in tableView(_:numberOfRowsInSection:).
				// Actually, it would be pretty easy to accommodate that extra state; we would return numberOfRowsAboveIndexedLibraryItems and set the "No Songs" placeholder. But I don't know how to put the "No Songs" placeholder below the album artwork and album info cells; setting it to tableView.backgroundView puts it in the center of the table view.
				lastRow: tableView.numberOfRows(inSection: section) - 1)
			
			indexedLibraryItems = refreshedItems
			
			tableView.performBatchUpdates {
				tableView.deleteRows(at: allIndexPathsInSection, with: .middle)
			} completion: { _ in
				self.didRefreshTableViewRows()
			}
			
			return
		}
		
		var indexPathsToMove = [(IndexPath, IndexPath)]()
		var indexPathsToInsert = [IndexPath]()
		
		for indexOfRefreshedItem in 0 ..< refreshedItems.count {
			let refreshedItem = refreshedItems[indexOfRefreshedItem]
			if let indexOfOnscreenItem = onscreenItems.firstIndex(where: { onscreenItem in
				onscreenItem.objectID == refreshedItem.objectID
			}) { // This item is already onscreen, and we still want it onscreen. If necessary, we'll move it. Later, if necessary, we'll update it.
				let startingIndexPath = IndexPath(
					row: indexOfOnscreenItem + numberOfRowsAboveIndexedLibraryItems,
					section: section)
				let endingIndexPath = IndexPath(
					row: indexOfRefreshedItem + numberOfRowsAboveIndexedLibraryItems,
					section: section)
				indexPathsToMove.append(
					(startingIndexPath, endingIndexPath))
				
			} else { // This item isn't onscreen yet, but we want it onscreen, so we'll have to add it.
				indexPathsToInsert.append(
					IndexPath(
						row: indexOfRefreshedItem + numberOfRowsAboveIndexedLibraryItems,
						section: section))
			}
		}
		
		var indexPathsToDelete = [IndexPath]()
		
		for index in 0 ..< onscreenItems.count {
			let onscreenItem = onscreenItems[index]
			if let _ = refreshedItems.firstIndex(where: { refreshedItem in
				refreshedItem.objectID == onscreenItem.objectID
			})  {
				continue // to the next onscreenItem
			} else {
				indexPathsToDelete.append(
					IndexPath(
						row: index + numberOfRowsAboveIndexedLibraryItems,
						section: section))
			}
		}
		
		indexedLibraryItems = refreshedItems
		
		tableView.performBatchUpdates {
			tableView.deleteRows(at: indexPathsToDelete, with: .middle)
			tableView.insertRows(at: indexPathsToInsert, with: .middle)
			for (startingIndexPath, endingIndexPath) in indexPathsToMove {
				tableView.moveRow(at: startingIndexPath, to: endingIndexPath)
			}
		} completion: { _ in
			self.didRefreshTableViewRows()
		}
		
	}
	
	// Easy to override.
	func didRefreshTableViewRows() {
		if indexedLibraryItems.count == 0 {
			performSegue(withIdentifier: "Deleted All Contents", sender: self)
			return
		} else {
			refreshTableViewRowContents()
		}
	}
	
	/*
	This is the final step in refreshTableView(forExistingItems:toMatchItems:inSection:). The earlier steps delete, insert, and move rows as necessary (with animations), and update indexedLibraryItems. This method's job is to update the data in those rows, which might be outdated: for example, songs' titles and albums' release date estimates might have changed.
	The simplest way to do this is to just call tableView.reloadData(). Infamously, that doesn't animate the changes, but we actually animated the deletes, inserts, and moves by ourselves earlier. All we're doing here is updating the data within each row, which generally looks fine without an animation. (If you wanted to add an animation, the most reasonable choice would probably be a fade.) With reloadData(), the overall animation for refreshing the table view becomes "animate all the row movements, and immediately after those movements end, instantly update the data in each row"—which looks fine.
	You should override this method if you want to add animations when refreshing the contents of the table view. For example, if it looks jarring to change the album artwork in the songs view without an animation, you might want to refresh that artwork with a fade animation, and leave the other rows to update without animations. The hard part is that you'll have to detect the existing content in each row in order to prevent an unnecessary animation if the content hasn't changed.
	*/
	@objc func refreshTableViewRowContents() {
		tableView.reloadData()
	}
	
	func didChangeAccentColor() {
		guard MPMediaLibrary.authorizationStatus() != .authorized else { return }
		tableView.reloadData()
	}
	
}
