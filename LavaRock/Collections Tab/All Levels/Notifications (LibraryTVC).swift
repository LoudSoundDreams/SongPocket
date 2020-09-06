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
		
		// Now we need to refresh our data and our views. But to do that, we won't pull the NSManagedObjectIDs out of this notification, because that's more logic for the same result. Instead, we'll just re-fetch our data and see how we need to update our views.
		
		print("")
		print(Self.self)
		print(String(describing: managedObjectContext.parent))
		
		refreshDataWithAnimationWhenVisible()
	}
	
	func refreshDataWithAnimationWhenVisible() {
		if view.window == nil {
			shouldRefreshDataWithAnimationOnNextViewDidAppear = true
		} else {
			refreshDataWithAnimation()
		}
	}
	
	// Easy to override.
	@objc func refreshDataWithAnimation() {
		
		// Remember: in CollectionsTVC and AlbumsTVC, we might be in "moving albums" mode.
		
		/*
		TO DO:
		
		- Hack this for SongsTVC.
		- Hack this for CollectionsTVC and AlbumsTVC while moving albums.
		- Hack this for MoveAlbumsClipboard.
		- Refresh containerOfData.
		
		update the navigation item title
		
		*/
		
		let refreshedItems = managedObjectContext.objectsFetched(for: coreDataFetchRequest)
		refreshTableView(
			forExistingItems: indexedLibraryItems,
			toMatchRefreshedItems: refreshedItems,
			inSection: 0,
			startingAtRow: numberOfRowsAboveIndexedLibraryItems)
	}
	
	// Easy to plug arguments into.
	func refreshTableView(
		forExistingItems onscreenItems: [NSManagedObject],
		toMatchRefreshedItems refreshedItems: [NSManagedObject],
		inSection section: Int,
		startingAtRow startingRow: Int
	) {
		
		guard refreshedItems.count >= 1 else {
			let allIndexPathsInSection = indexPathsEnumeratedIn(
				section: section,
				firstRow: 0,
				lastRow: tableView.numberOfRows(inSection: section))
			tableView.performBatchUpdates {
				tableView.deleteRows(at: allIndexPathsInSection, with: .middle)
//				tableView.deleteSections(section, with: .middle)
			} completion: { _ in
				self.didRefreshTableViewRows()
			}
			return
		}
		
		var indexPathsToMove = [(IndexPath, IndexPath)]()
		var indexPathsToInsert = [IndexPath]()
		
		for indexOfRefreshedItem in 0 ..< refreshedItems.count {
			let refreshedItem = refreshedItems[indexOfRefreshedItem]
			if let indexOfOnscreenItem = indexedLibraryItems.firstIndex(where: { onscreenItem in
				onscreenItem.objectID == refreshedItem.objectID
			}) { // This item is already onscreen, and we still want it onscreen. If necessary, we'll move it. Later, if necessary, we'll update it.
				let startingIndexPath = IndexPath(
					row: startingRow + indexOfOnscreenItem,
					section: section)
				let endingIndexPath = IndexPath(
					row: startingRow + indexOfRefreshedItem,
					section: section)
				indexPathsToMove.append(
					(startingIndexPath, endingIndexPath))
				
			} else { // This item isn't onscreen yet, but we want it onscreen, so we'll have to add it.
				indexPathsToInsert.append(
					IndexPath(
						row: startingRow + indexOfRefreshedItem,
						section: section))
			}
		}
		
		var indexPathsToDelete = [IndexPath]()
		
		for index in 0 ..< indexedLibraryItems.count {
			let onscreenItem = indexedLibraryItems[index]
			if let _ = refreshedItems.firstIndex(where: { refreshedItem in
				refreshedItem.objectID == onscreenItem.objectID
			})  {
				continue // to the next onscreenItem
			} else {
				indexPathsToDelete.append(
					IndexPath(
						row: startingRow + index,
						section: section))
			}
		}
		
//		print("Deleting rows at: \(indexPathsToDelete)")
//		print("Inserting rows at: \(indexPathsToInsert)")
//		print("Moving rows at: \(indexPathsToMove)")
		
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
			refreshTableViewData()
		}
	}
	
	/*
	This method is the final step in refreshDataWithAnimation(). The earlier steps delete, insert, and move rows as necessary (with animations), and update the data sources (including indexedLibraryItems). This method's job is to update the data in those rows, which might be outdated: for example, songs' titles and albums' release date estimates.
	The simplest way to do this is to just call tableView.reloadData(). That's infamous for not animating the changes, but we actually animated the deletes, inserts, and moves by ourselves earlier. All we're doing here is updating the data within each row, which generally looks fine without an animation. (If you wanted to add an animation, the most reasonable choice would probably be a fade). With reloadData(), the overall animation for refreshDataWithAnimation() becomes "animate all the row movements, and the instant those movements end, instantly change the data in each row to reflect any updates"—which looks fine.
	You should override this method if you want to add an animation when you update any data. For example, if it looks jarring to change the album artwork in the songs view without an animation, you might want to refresh that artwork with a fade animation, and leave the rest of the views to update without animations.
	*/
	@objc func refreshTableViewData() {
		tableView.reloadData()
	}
	
	func didChangeAccentColor() {
		guard MPMediaLibrary.authorizationStatus() != .authorized else { return }
		tableView.reloadData()
	}
	
}
