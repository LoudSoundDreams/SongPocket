//
//  LibraryTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-08-29.
//

import UIKit
import MediaPlayer
import CoreData

extension LibraryTVC {
	
	// MARK: - Setup and Teardown
	
	// Subclasses that override this method should call super (this implementation) at the beginning of the override.
	@objc func beginObservingNotifications() {
		NotificationCenter.default.removeObserver(self)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserveLRDidChangeAccentColor),
			name: Notification.Name.LRDidChangeAccentColor,
			object: nil)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserveLRDidSaveChangesFromMusicLibrary),
			name: Notification.Name.LRDidSaveChangesFromMusicLibrary,
			object: nil)
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObservePossiblePlaybackStateChange),
			name: UIApplication.didBecomeActiveNotification,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObservePossiblePlaybackStateChange),
			name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObservePossiblePlaybackStateChange),
			name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
			object: nil)
	}
	
	final func endObservingNotifications() {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Responding
	
	@objc private func didObserveLRDidChangeAccentColor() {
		tableView.reloadData()
	}
	
	@objc private func didObserveLRDidSaveChangesFromMusicLibrary() {
		PlayerManager.refreshSongInPlayer() // Call this from here, not from within PlayerManager, because this instance needs to guarantee that this has been done before it continues.
		refreshToReflectMusicLibrary()
	}
	
	@objc private func didObservePossiblePlaybackStateChange() {
		PlayerManager.refreshSongInPlayer() // Call this from here, not from within PlayerManager, because this instance needs to guarantee that this has been done before it continues.
		refreshToReflectPlaybackState()
	}
	
	// MARK: - After Possible Playback State Change
	
	// Subclasses that show a "now playing" indicator should override this method, call super (this implementation), and update that indicator.
	@objc func refreshToReflectPlaybackState() {
		// We want every LibraryTVC to have its playback toolbar refreshed before it appears. This tells all LibraryTVCs to refresh, even if they aren't onscreen. This works; it's just unusual.
		refreshBarButtons()
	}
	
	// LibraryTVC itself doesn't call this, but its subclasses might want to.
	final func refreshNowPlayingIndicators(
		isInPlayerDeterminer: (IndexPath) -> Bool
	) {
		let isPlaying = sharedPlayer?.playbackState == .playing
		for indexPath in indexPaths(forIndexOfSectionOfLibraryItems: 0) {
			guard var cell = tableView.cellForRow(at: indexPath) as? NowPlayingIndicatorDisplayer else { continue }
			let isInPlayer = isInPlayerDeterminer(indexPath)
			let indicator = NowPlayingIndicator(
				isInPlayer: isInPlayer,
				isPlaying: isPlaying)
			cell.apply(indicator)
		}
	}
	
	// MARK: - After Importing Changes from Music Library
	
	private func refreshToReflectMusicLibrary() {
		refreshToReflectPlaybackState() // Do this even for views that aren't visible, so that when we reveal them by swiping back, the "now playing" indicators and playback toolbar are already updated.
		refreshLibraryItemsWhenVisible()
	}
	
	// MARK: Refreshing Library Items
	
	final func refreshLibraryItemsWhenVisible() {
		if view.window == nil {
			needsRefreshLibraryItemsOnViewDidAppear = true
		} else {
			refreshLibraryItems()
		}
	}
	
	@objc func refreshLibraryItems() {
		isImportingChanges = false
//		refreshAndSetBarButtons(animated: false) // Revert spinner back to Edit button
		
		/*
		 // When we need to refresh, you might be in the middle of a content-dependent task. Cancel those content-dependent tasks.
		 - Sort options (LibraryTVC)
		 - "Rename Collection" dialog (CollectionsTVC)
		 - "Combine Collections" dialog (CollectionsTVC)
		 - "Move Albums to…" sheet (CollectionsTVC and AlbumsTVC when in "moving Albums" mode)
		 - "New Collection" dialog (CollectionsTVC when in "moving Albums" mode)
		 - Song actions (SongsTVC)
		 - (Editing mode is a special state, but refreshing in editing mode is fine (with no other "breath-holding modes" presented).)
		 */
		let shouldNotDismissAnyModalViewControllers
		= (presentedViewController as? UINavigationController)?.viewControllers.first is OptionsTVC
		if !shouldNotDismissAnyModalViewControllers {
			view.window?.rootViewController?.dismiss(animated: true) {
				refreshLibraryItemsPart2()
			}
		} else {
			refreshLibraryItemsPart2()
		}
		
		func refreshLibraryItemsPart2() {
			let newItems = sectionOfLibraryItems.itemsFetched(via: managedObjectContext)
			sectionOfLibraryItems.refreshContainer(via: managedObjectContext)
			setItemsAndRefreshTableView(newItems: newItems) {
				self.refreshNavigationItemTitle()
				self.tableView.reloadData() // Update the data within each row, which might be outdated.
				// This has no animation (infamously), but we animated the deletes, inserts, and moves earlier, so here, it just updates the data within the rows after they stop moving, which looks fine.
				// This includes tableView(_:numberOfRowsInSection:), which includes refreshBarButtons(), which includes refreshPlaybackToolbarButtons(), which we need to call at some point before our work here is done.
			}
		}
	}
	
}
