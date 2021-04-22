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
		PlayerControllerManager.refreshCurrentSong() // Call this from here, not from within PlayerControllerManager, because this instance needs to guarantee that this has been done before it continues.
		refreshToReflectMusicLibrary()
	}
	
	@objc private func didObservePossiblePlaybackStateChange() {
		PlayerControllerManager.refreshCurrentSong() // Call this from here, not from within PlayerControllerManager, because this instance needs to guarantee that this has been done before it continues.
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
		isItemNowPlayingDeterminer: (IndexPath) -> Bool
	) {
		for indexPath in tableView.indexPathsForRows(
			inSection: 0,
			firstRow: numberOfRowsAboveLibraryItems)
		{
			guard var cell = tableView.cellForRow(at: indexPath) as? NowPlayingIndicator else { continue } // TO DO: For some reason, this can trigger tableView(_:cellForRowAt:), which can redraw the cell to a null placeholder, which we can't allow.
			let isItemNowPlaying = isItemNowPlayingDeterminer(indexPath)
			let indicator = PlayerControllerManager.nowPlayingIndicator(
				isItemNowPlaying: isItemNowPlaying)
			cell.applyNowPlayingIndicator(indicator)
		}
	}
	
	// MARK: - After Importing Changes from Music Library
	
	private func refreshToReflectMusicLibrary() {
		refreshToReflectPlaybackState() // Do this even for views that aren't visible, so that when we reveal them by swiping back, the "now playing" indicators and playback toolbar are already updated.
		refreshDataAndViewsWhenVisible()
	}
	
	// MARK: Refreshing Data and Views
	
	final func refreshDataAndViewsWhenVisible() {
		if view.window == nil {
			shouldRefreshDataAndViewsOnNextViewDidAppear = true
		} else {
			refreshDataAndViews()
		}
	}
	
	@objc func refreshDataAndViews() {
		isImportingChanges = false
//		refreshAndSetBarButtons(animated: false) // Revert spinner back to Edit button
		
		/*
		// When we need to refresh, you might be in the middle of a content-dependent task. Cancel those content-dependent tasks.
		// TO DO: Only cancel if we'll move rows during the refresh.
		- Sort options (LibraryTVC)
		- "Rename Collection" dialog (CollectionsTVC)
		- "Move Albums" sheet (CollectionsTVC and AlbumsTVC when in "moving Albums" mode)
		- "New Collection" dialog (CollectionsTVC when in "moving Albums" mode)
		- Song actions (SongsTVC)
		- (Editing mode is a special state, but refreshing in editing mode is fine (with no other "breath-holding modes" presented).)
		*/
		let shouldNotDismissAnyModalViewControllers =
			(presentedViewController as? UINavigationController)?.viewControllers.first is OptionsTVC
		if !shouldNotDismissAnyModalViewControllers {
			view.window?.rootViewController?.dismiss(
				animated: true,
				completion: refreshDataAndViewsPart2)
		} else {
			refreshDataAndViewsPart2()
		}
		
		func refreshDataAndViewsPart2() {
			let newItems = sectionOfLibraryItems.fetchedItems()
			setItemsAndRefreshTableView(
				newItems: newItems,
				completion: {
					self.sectionOfLibraryItems.refreshContainer()
					self.refreshNavigationItemTitle()
					self.tableView.reloadData() // Update the data within each row, which might be outdated.
					// This has no animation (infamously), but we animated the deletes, inserts, and moves earlier, so here, it just updates the data within the rows after they stop moving, which looks fine.
					// This includes tableView(_:numberOfRowsInSection:), which includes refreshBarButtons(), which includes refreshPlaybackToolbarButtons(), which we need to call at some point before our work here is done.
				})
		}
	}
	
}
