//
//  LibraryTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-08-29.
//

import UIKit
import MediaPlayer
import CoreData
import SwiftUI

extension LibraryTVC: PlaybackStateReflecting {
	func reflectPlaybackState() {
		reflectPlayer()
	}
}

extension LibraryTVC {
	// MARK: - Setup
	
	// Overrides should call super (this implementation).
	@objc func beginObservingNotifications() {
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(didMergeChanges),
			name: .LRDidMergeChanges,
			object: nil)
		
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(nowPlayingItemDidChange),
				name: .MPMusicPlayerControllerNowPlayingItemDidChange,
				object: nil)
		}
	}
	@objc private func didMergeChanges() { reflectDatabase() }
	@objc private func nowPlayingItemDidChange() { reflectPlayer() }
	
	// MARK: - Database
	
	final func reflectDatabase() {
		reflectPlayer() // Do this even for views that aren't visible, so that when we reveal them by going back, the "now playing" indicators and playback toolbar are already updated.
		refreshLibraryItemsWhenVisible()
	}
	
	// MARK: Player
	
	// Subclasses that show a "now playing" indicator should override this method, call super (this implementation), and update that indicator.
	@objc func reflectPlayer() {
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
	
	// MARK: Library Items
	
	final func refreshLibraryItemsWhenVisible() {
		if view.window == nil {
			needsRefreshLibraryItemsOnViewDidAppear = true
		} else {
			refreshLibraryItems()
		}
	}
	
	@MainActor
	@objc func refreshLibraryItems() {
		isMergingChanges = false
		
		/*
		 // When we need to refresh, you might be in the middle of a content-dependent task. Cancel such tasks, for simplicity.
		 - Sort options (LibraryTVC)
		 - “Rename Collection” dialog (CollectionsTVC)
		 - “Combine Collections” dialog (CollectionsTVC)
		 - “Organize or move albums?” menu (AlbumsTVC)
		 - “Organize albums” sheet (CollectionsTVC and AlbumsTVC when in “organize albums” sheet)
		 - “Move albums” sheet (CollectionsTVC and AlbumsTVC when in “move albums” sheet)
		 - “New Collection” dialog (CollectionsTVC when in “move albums” sheet)
		 - Song actions (SongsTVC)
		 - (Editing mode is a special state, but refreshing in editing mode is fine (with no other “breath-holding modes” presented).)
		 */
		let shouldNotDismissAnyModalVCs
		= (presentedViewController as? UINavigationController)?.viewControllers.first is OptionsTVC
		|| presentedViewController is UIHostingController<OptionsView>
		Task {
			if !shouldNotDismissAnyModalVCs {
				await view.window?.rootViewController?.dismiss_async(animated: true)
			}
			
			let newViewModel = viewModel.updatedWithRefreshedData()
			await setViewModelAndMoveRows_async(newViewModel)
			
			refreshNavigationItemTitle()
			// Update the data within each row (and header), which might be outdated.
			// Doing it without an animation looks fine, because we animated the deletes, inserts, and moves earlier; here, we just change the contents of the rows after they stop moving.
			tableView.reconfigureRows(at: tableView.indexPathsForVisibleRowsNonNil)
		}
	}
}
