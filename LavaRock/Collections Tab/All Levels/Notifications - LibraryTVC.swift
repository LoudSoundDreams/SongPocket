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
	
	final func beginObservingNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.LRDidSaveChangesFromMusicLibrary,
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
	}
	
	final func endObservingNotifications() {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Responding
	
	// After observing notifications, funnel control flow through here, rather than calling methods directly, to make debugging easier.
	@objc private func didObserve(_ notification: Notification) {
		switch notification.name {
		case .LRDidSaveChangesFromMusicLibrary:
			PlayerControllerManager.shared.refreshCurrentSong() // Do this here, not within PlayerControllerManager, because we need to do it in response to certain notifications, and this class might observe those notifications before PlayerControllerManager does.
			refreshToReflectMusicLibrary()
		case .LRDidChangeAccentColor:
			didChangeAccentColor()
		case
			UIApplication.didBecomeActiveNotification,
			.MPMusicPlayerControllerPlaybackStateDidChange,
			.MPMusicPlayerControllerNowPlayingItemDidChange
		:
			PlayerControllerManager.shared.refreshCurrentSong() // Do this here, not within PlayerControllerManager, because we need to do it in response to certain notifications, and this class might observe those notifications before PlayerControllerManager does.
			refreshToReflectPlaybackState()
		default:
			print("An instance of \(Self.self) observed the notification: \(notification.name)")
			print("… but is not set to do anything after observing that notification.")
		}
	}
	
	// MARK: - After Possible Playback State Change
	
	// Subclasses that show a "now playing" indicator should override this method, call super (this implementation), and update that indicator.
	@objc func refreshToReflectPlaybackState() {
		refreshBarButtons() // We want every LibraryTVC to have its playback toolbar refreshed before it appears. This tells all LibraryTVCs to refresh, even if they aren't onscreen. This works; it's just unusual.
	}
	
	// LibraryTVC itself doesn't call this, but its subclasses might want to.
	final func refreshNowPlayingIndicators(
		isItemNowPlayingDeterminer: (IndexPath) -> Bool
	) {
		for indexPath in tableView.indexPathsForRowsIn(
			section: 0,
			firstRow: numberOfRowsAboveIndexedLibraryItems)
		{
			guard var cell = tableView.cellForRow(at: indexPath) as? NowPlayingIndicator else { continue }
			let isItemNowPlaying = isItemNowPlayingDeterminer(indexPath)
			let indicator = PlayerControllerManager.shared.nowPlayingIndicator(
				isItemNowPlaying: isItemNowPlaying)
			cell.applyNowPlayingIndicator(indicator)
		}
	}
	
	// MARK: - After Importing Changes from Music Library
	
	private func refreshToReflectMusicLibrary() {
		refreshToReflectPlaybackState() // Do this even for views that aren't visible, so that when we reveal them by swiping back, the "now playing" indicators are already updated.
		
		if refreshesAfterDidSaveChangesFromMusicLibrary {
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
	
	final func refreshDataAndViews() {
		// TO DO: Put the UI into an "Importing…" state.
		
		let refreshedItems = managedObjectContext.objectsFetched(for: coreDataFetchRequest)
		prepareToRefreshDataAndViews(consideringRefreshedItems: refreshedItems)
		
		// TO DO: Take the UI out of an "Importing…" state after all animations complete.
		
		refreshTableView(
			section: 0,
			onscreenItems: indexedLibraryItems,
			refreshedItems: refreshedItems,
			completion: refreshData) // refreshData includes tableView.reloadData(), which includes tableView(_:numberOfRowsInSection:), which includes refreshBarButtons(), which includes refreshPlaybackToolbarButtons(), which we need to call at some point before our work here is done.
	}
	
	/*
	Easy to override. You should call super (this implementation) in your override.
	You might have content-dependent, blocking actions onscreen while we we need to refresh. If so, override this method and cancel those actions, if the refresh will change the content that those actions would have applied to. Typically, you should cancel those actions if refreshedItems is different from indexedLibraryItems.
	These are the content-dependent, blocking actions we need to account for:
	- Sort options (LibraryTVC)
	- "Rename Collection" dialog (CollectionsTVC)
	- "Move Albums" sheet (CollectionsTVC, AlbumsTVC when in "moving Albums" mode)
	- "New Collection" dialog (CollectionsTVC when in "moving Albums" mode)
	- Song actions (SongsTVC)
	Editing mode is a special state, but refreshing in editing mode is fine (with no other "breath-holding modes" presented).
	*/
	@objc func prepareToRefreshDataAndViews(
		consideringRefreshedItems refreshedItems: [NSManagedObject]
	) {
		if
			areSortOptionsPresented,
			refreshedItems != indexedLibraryItems
		{
			dismiss(animated: true, completion: nil)
			areSortOptionsPresented = false
		}
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
				guard startingIndexPath != endingIndexPath else { continue } // (Might) prevent the table view from unnecessarily scrolling the top row to the top of the screen.
				tableView.moveRow(at: startingIndexPath, to: endingIndexPath)
			}
		} completion: { _ in completion?() }
	}
	
	private func deleteAllRowsThenExit() {
		var allIndexPaths = [IndexPath]()
		for section in 0 ..< tableView.numberOfSections {
			let allIndexPathsInSection =
				tableView.indexPathsForRowsIn(section: section, firstRow: 0)
			allIndexPaths.append(contentsOf: allIndexPathsInSection)
		}
		indexedLibraryItems.removeAll()
		tableView.performBatchUpdates {
			tableView.deleteRows(at: allIndexPaths, with: .middle)
		} completion: { _ in
			guard !(self is CollectionsTVC) else { return }
			self.performSegue(withIdentifier: "Removed All Contents", sender: self)
		}
	}
	
	@objc func refreshData() {
		guard indexedLibraryItems.count >= 1 else { return }
		refreshContainerOfLibraryItems()
		refreshTableViewRowContents()
	}
	
	// Subclasses that show information about containerOfLibraryItems in their views should subclass this method by calling super (this implementation) and then updating those views with the refreshed containerOfLibraryItems.
	@objc func refreshContainerOfLibraryItems() {
		guard let containerOfLibraryItems = containerOfLibraryItems else { return }
		managedObjectContext.refresh(containerOfLibraryItems, mergeChanges: true)
	}
	
	/*
	This is the final step in refreshTableView. The earlier steps delete, insert, and move rows as necessary (with animations), and update indexedLibraryItems. This method updates the data within each row, which might be outdated: for example, songs' titles and albums' release dates.
	The simplest way to do this is to just call tableView.reloadData(). Infamously, that has no animation, but we actually animated the deletes, inserts, and moves by ourselves earlier. All reloadData() does here is update the data within each row without an animation, which usually looks okay.
	You should override this method if you want to add animations when refreshing the contents of any part of table view. For example, if it looks jarring to change some artwork without an animation, you might want to refresh that artwork with a fade animation, but leave the other rows to update without animations. The hard part is that to prevent unnecessary animations when the content hasn't changed, you'll have to detect the existing content in each row.
	*/
	@objc func refreshTableViewRowContents() {
		tableView.reloadData()
	}
	
	// MARK: - After Changing Accent Color
	
	private func didChangeAccentColor() {
		tableView.reloadData()
	}
	
}
