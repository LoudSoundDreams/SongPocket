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
	
	// Overrides of this method should call super (this implementation) at the beginning.
	@objc func beginObservingNotifications() {
		NotificationCenter.default.removeObserver(self)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didImportChanges),
			name: Notification.Name.LRDidImportChanges,
			object: nil)
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(playbackStateMaybeDidChange),
			name: UIApplication.didBecomeActiveNotification,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(playbackStateMaybeDidChange),
			name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(playbackStateMaybeDidChange),
			name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
			object: nil)
	}
	
	final func endObservingNotifications() {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: Responding
	
	@objc private func didImportChanges() {
		PlayerManager.refreshSongInPlayer() // Call this from here, not from within PlayerManager, because this instance needs to guarantee that this has been done before it continues.
		refreshToReflectMusicLibrary()
	}
	
	@objc private func playbackStateMaybeDidChange(
		accordingTo notification: Notification
	) {
//		print(notification.name)
		PlayerManager.refreshSongInPlayer() // Call this from here, not from within PlayerManager, because this instance needs to guarantee that this has been done before it continues.
		reflectPlaybackState()
	}
	
	// MARK: - After Possible Playback State Change
	
	// Subclasses that show a "now playing" indicator should override this method, call super (this implementation), and update that indicator.
	@objc func reflectPlaybackState() {
		// We want every LibraryTVC to have its playback toolbar refreshed before it appears. This tells all LibraryTVCs to refresh, even if they aren't onscreen. This works; it's just unusual.
		refreshPlaybackButtons()
	}
	
	// LibraryTVC itself doesn't call this, but its subclasses might want to.
	final func refreshNowPlayingIndicators(
		nowPlayingDetermining: NowPlayingDetermining
	) {
		let isPlaying = sharedPlayer?.playbackState == .playing
		viewModel.indexPathsForAllItems().forEach { indexPath in
			guard var cell = tableView.cellForRow(at: indexPath) as? NowPlayingIndicating else { return }
			let isInPlayer = nowPlayingDetermining.isInPlayer(libraryItemAt: indexPath)
			let indicator = NowPlayingIndicator(
				isInPlayer: isInPlayer,
				isPlaying: isPlaying)
			cell.applyNowPlayingIndicator(indicator)
		}
	}
	
	// MARK: - After Importing Changes from Music Library
	
	private func refreshToReflectMusicLibrary() {
		reflectPlaybackState() // Do this even for views that aren't visible, so that when we reveal them by going back, the "now playing" indicators and playback toolbar are already updated.
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
			let newItemsAndSections = viewModel.newItemsAndSections()
			newItemsAndSections.reversed().forEach { (newItems, section) in
				
				setItemsAndMoveRows(
					newItems: newItems,
					section: section
				) {
					if self.viewModel.indexOfGroup(forSection: section) == 0 { // So that we only do this once.
						self.viewModel.refreshContainersAndReflect()
						
						self.tableView.reloadData() // Update the data within each row, which might be outdated. This infamously has no animation, but we animated the deletes, inserts, and moves earlier, so here, it just changes the contents of the rows after they stop moving, which looks fine.
						// Also reloads headers. (Is that the only way?)
						
						self.didChangeRowsOrSelectedRows() // Because reloadData deselects all rows.
					}
				}
				
			}
		}
	}
	
}
