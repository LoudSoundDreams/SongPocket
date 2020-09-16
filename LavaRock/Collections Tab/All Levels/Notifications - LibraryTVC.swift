//
//  Notifications - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-29.
//

import UIKit
import MediaPlayer
import CoreData

extension LibraryTVC {
	
	// MARK: - Setup and Teardown
	
	@objc func beginObservingAndGeneratingNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.LRDidSaveChangesFromAppleMusic,
			object: nil)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.LRDidChangeAccentColor,
			object: nil)
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: UIApplication.didBecomeActiveNotification,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
			object: nil)
		playerController?.beginGeneratingPlaybackNotifications()
		
		// Experimental
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMusicPlayerControllerQueueDidChange,
			object: nil)
	}
	
	func endObservingNotifications() {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Responding
	
	@objc func didObserve(_ notification: Notification) {
		switch notification.name {
		case .LRDidSaveChangesFromAppleMusic:
			didSaveChangesFromAppleMusic()
		case .LRDidChangeAccentColor:
			didChangeAccentColor()
		case
			UIApplication.didBecomeActiveNotification,
			.MPMusicPlayerControllerPlaybackStateDidChange,
			.MPMusicPlayerControllerNowPlayingItemDidChange
		:
			refreshDataAndViews() // Refresh the "current song" indicator, and refresh the bar buttons. Don't use tableView.reloadData() (even though that triggers refreshBarButtons()), because that beats didSaveChangesFromAppleMusic() to refreshing the UI.
		default:
			print("An instance of \(Self.self) observed the notification: \(notification.name)")
			print("… but is not set to do anything after observing that notification.")
		}
	}
	
	// MARK: - After Merge from Apple Music Library
	
	private func didSaveChangesFromAppleMusic() {
		if refreshesAfterDidSaveChangesFromAppleMusic {
			refreshDataAndViewsWhenVisible()
		}
	}
	
	// MARK: Refreshing Data and Views
	
	final func refreshDataAndViewsWhenVisible() {
		if view.window == nil {
			shouldRefreshOnNextViewDidAppear = true
		} else {
			refreshDataAndViews()
		}
	}
	
	/*
	Easy to override. You'll probably want to call super (this implementation) after your additional code.
	Before calling this implementation, you should cancel any content-dependent actions, including:
	- Sort options (LibraryTVC)
	- "Rename Collection" dialog (CollectionsTVC)
	- "Move albums" sheet (CollectionsTVC, AlbumsTVC when in "moving albums" mode)
	- "New Collection" dialog (CollectionsTVC when in "moving albums" mode)
	- Song actions (SongsTVC)
	Editing mode is a special state, but refreshing in editing mode is fine (with no other "breath-holding modes" presented).
	*/
	@objc func refreshDataAndViews() {
		/*
		print("")
		print(Self.self)
		print(String(describing: managedObjectContext.parent))
		*/
		
		if areSortOptionsPresented {
			dismiss(animated: true, completion: nil)
			areSortOptionsPresented = false
		}
		
		let refreshedItems = managedObjectContext.objectsFetched(for: coreDataFetchRequest)
//		print(indexedLibraryItems)
//		print(refreshedItems)
		refreshTableView(
			section: 0,
			onscreenItems: indexedLibraryItems,
			refreshedItems: refreshedItems,
			completion: refreshData)
	}
	
	// Easy to plug arguments into. You can call this on its own, separate from refreshDataAndViews().
	// Note: Even though this method is easy to plug arguments into, it (currently) has side effects: it replaces indexedLibraryItems with the onscreenItems array that you pass in.
	func refreshTableView(
		section: Int,
		onscreenItems: [NSManagedObject],
		refreshedItems: [NSManagedObject],
		completion: (() -> ())?
	) {
		guard refreshedItems.count >= 1 else {
			deleteAllRowsThenExit()
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
//				guard startingIndexPath != endingIndexPath else { continue } // The table view tends to move to unnecessarily scroll the top row to the top of the screen. As of iOS 14.0 beta 8, this *doesn't* prevent it.
				tableView.moveRow(at: startingIndexPath, to: endingIndexPath)
			}
		} completion: { _ in (completion ?? { })() }
	}
	
	final func deleteAllRowsThenExit() {
		var allIndexPaths = [IndexPath]()
		for section in 0 ..< tableView.numberOfSections {
			let allIndexPathsInSection = indexPathsEnumeratedIn(
				section: section,
				firstRow: 0,
				lastRow: tableView.numberOfRows(inSection: section) - 1)
			allIndexPaths.append(contentsOf: allIndexPathsInSection)
		}
		indexedLibraryItems.removeAll()
		tableView.performBatchUpdates {
			tableView.deleteRows(at: allIndexPaths, with: .middle)
		} completion: { _ in
//			self.setEditing(false, animated: true) // Doesn't seem to do anything
			guard !(self is CollectionsTVC) else { return }
			self.performSegue(withIdentifier: "Removed All Contents", sender: self)
		}
	}
	
	@objc func refreshData() {
		guard indexedLibraryItems.count >= 1 else { return }
		refreshContainerOfData()
		refreshTableViewRowContents()
	}
	
	// Subclasses that show data from containerOfData in their views should subclass this method by calling super (this implementation) and then updating those views with the refreshed containerOfData.
	@objc func refreshContainerOfData() {
		guard let containerOfData = containerOfData else { return }
		managedObjectContext.refresh(containerOfData, mergeChanges: true)
	}
	
	/*
	This is the final step in refreshTableView. The earlier steps delete, insert, and move rows as necessary (with animations), and update indexedLibraryItems. This method's job is to update the data in those rows, which might be outdated: for example, songs' titles and albums' release date estimates might have changed.
	The simplest way to do this is to just call tableView.reloadData(). Infamously, that doesn't animate the changes, but we actually animated the deletes, inserts, and moves by ourselves earlier. All we're doing here is updating the data within each row, which generally looks fine without an animation. (If you wanted to add an animation, the most reasonable choice would probably be a fade.) With reloadData(), the overall animation for refreshing the table view becomes "animate all the row movements, and immediately after those movements end, instantly update the data in each row"—which looks fine.
	You should override this method if you want to add animations when refreshing the contents of the table view. For example, if it looks jarring to change the album artwork in the songs view without an animation, you might want to refresh that artwork with a fade animation, and leave the other rows to update without animations. The hard part is that you'll have to detect the existing content in each row in order to prevent an unnecessary animation if the content hasn't changed.
	*/
	@objc func refreshTableViewRowContents() {
		tableView.reloadData()
	}
	
	// MARK: - After Changing Accent Color
	
	private func didChangeAccentColor() {
		tableView.reloadData()
	}
	
}
