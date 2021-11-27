//
//  LibraryTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-08-29.
//

import UIKit
import MediaPlayer
import CoreData

extension LibraryTVC: PlaybackStateReflecting {
	
	func reflectPlaybackState() {
		playbackStateOrNowPlayingItemChanged()
	}
	
}

extension LibraryTVC {
	
	// MARK: - Setup and Teardown
	
	// Overrides should call super (this implementation).
	@objc func beginObservingNotifications() {
		NotificationCenter.default.removeAndAddObserver(
			self,
			selector: #selector(didImportChanges),
			name: .LRDidImportChanges,
			object: nil)
		
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.removeAndAddObserver(
				self,
				selector: #selector(playbackStateOrNowPlayingItemChanged),
				name: .MPMusicPlayerControllerNowPlayingItemDidChange,
				object: nil)
		}
	}
	
	@objc private func didImportChanges() {
		refreshLibraryItemsAndReflect()
	}
	
	@objc private func playbackStateOrNowPlayingItemChanged() {
		reflectPlaybackStateAndNowPlayingItem()
	}
	
	// MARK: - After Playback State or "Now Playing" Item Changes
	
	// Subclasses that show a "now playing" indicator should override this method, call super (this implementation), and update that indicator.
	@objc func reflectPlaybackStateAndNowPlayingItem() {
		// We want every LibraryTVC to have its playback toolbar refreshed before it appears. This tells all LibraryTVCs to refresh, even if they aren't onscreen. This works; it's just unusual.
		refreshPlaybackButtons()
	}
	
	// `LibraryTVC` itself doesn't call this, but its subclasses might want to.
	final func refreshNowPlayingIndicators(
		nowPlayingDetermining: NowPlayingDetermining
	) {
		let isPlaying = sharedPlayer?.playbackState == .playing
		tableView.indexPathsForVisibleRowsNonNil.forEach { visibleIndexPath in
			guard var cell = tableView.cellForRow(at: visibleIndexPath) as? NowPlayingIndicating else { return }
			let isInPlayer = nowPlayingDetermining.isInPlayer(anyIndexPath: visibleIndexPath)
			let indicator = NowPlayingIndicator(
				isInPlayer: isInPlayer,
				isPlaying: isPlaying)
			cell.applyNowPlayingIndicator(indicator)
		}
	}
	
	// MARK: - After Importing Changes from Music Library
	
	private func refreshLibraryItemsAndReflect() {
		reflectPlaybackStateAndNowPlayingItem() // Do this even for views that aren't visible, so that when we reveal them by going back, the "now playing" indicators and playback toolbar are already updated.
		refreshLibraryItemsWhenVisible()
	}
	
	// MARK: - Refreshing Library Items
	
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
		let shouldNotDismissAnyModalVCs
		= (presentedViewController as? UINavigationController)?.viewControllers.first is OptionsTVC
		if !shouldNotDismissAnyModalVCs {
			view.window?.rootViewController?.dismiss(animated: true) {
				refreshLibraryItemsPart2()
			}
		} else {
			refreshLibraryItemsPart2()
		}
		
		func refreshLibraryItemsPart2() {
			let newViewModel = viewModel.refreshed()
			setViewModelAndMoveRows(newViewModel) {
				self.refreshNavigationItemTitle()
				
				// Update the data within each row (and header), which might be outdated.
				// Doing it without an animation looks fine, because we animated the deletes, inserts, and moves earlier; here, we just change the contents of the rows after they stop moving.
				if #available(iOS 15, *) {
					self.tableView.reconfigureRows(at: self.tableView.indexPathsForVisibleRowsNonNil)
				} else {
					self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRowsNonNil, with: .none)
				}
			}
		}
		
	}
	
}
