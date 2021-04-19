//
//  Notifications - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// MARK: - Setup
	
	final override func beginObservingNotifications() {
		super.beginObservingNotifications()
		
		if albumMoverClipboard != nil {
		} else {
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(didObserveLRDidMoveAlbums),
				name: Notification.Name.LRDidMoveAlbums,
				object: nil)
		}
	}
	
	// MARK: - After Moving Albums
	
	@objc private func didObserveLRDidMoveAlbums() {
		didMoveAlbums = true
	}
	
	// MARK: - After Possible Playback State Change
	
	final override func refreshToReflectPlaybackState() {
		super.refreshToReflectPlaybackState()
		
		refreshNowPlayingIndicators(isItemNowPlayingDeterminer: isItemNowPlaying(at:))
	}
	
	// MARK: - Refreshing Data and Views
	
	/*
	When moving Albums:
	- What if any of the Albums we're moving get deleted?
	- What if we've already made a new Collection and are transitioning into or out of it?
	Currently, we're just dismissing the "move Albums" sheet to not deal with any of those edge cases.
	*/
	
	final override func willRefreshDataAndViews() {
		if isLoading {
			didJustFinishLoading = true
			let indexPath = IndexPath(row: 0, section: 0)
			tableView.deleteRows(at: [indexPath], with: .middle)
			didJustFinishLoading = false
		}
		
		super.willRefreshDataAndViews()
	}
	
	// This is the same as in AlbumsTVC.
	final override func didDismissAllModalViewControllers() {
		super.didDismissAllModalViewControllers()
		
		if let albumMoverClipboard = albumMoverClipboard {
			albumMoverClipboard.delegate?.didAbort() // This solves the case where you deleted all the Albums in the Collection that you were moving Albums out of; it exits the now-empty Collection and removes it.
		}
	}
	
	// This is the same as in AlbumsTVC.
	final override func shouldContinueAfterWillRefreshDataAndViews() -> Bool {
		if albumMoverClipboard != nil {
			return false
		} else {
			return true
		}
	}
	
}
