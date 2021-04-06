//
//  Notifications - AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-03.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// MARK: - After Possible Playback State Change
	
	final override func refreshToReflectPlaybackState() {
		super.refreshToReflectPlaybackState()
		
		refreshNowPlayingIndicators(isItemNowPlayingDeterminer: isItemNowPlaying(at:))
	}
	
	// MARK: - Refreshing Data and Views
	
	/*
	All special cases in AlbumsTVC:
	- In "moving Albums" mode and in existing Collection
	- In "moving Albums" mode and in new Collection
	- If any of the Albums we're moving get deleted
	*/
	
	// This is the same as in CollectionsTVC.
	final override func didDismissAllModalViewControllers() {
		super.didDismissAllModalViewControllers()
		
		if let albumMoverClipboard = albumMoverClipboard {
			// didAbort() solves the case where you deleted all the Albums in the Collection that you were moving Albums out of; it exits the now-empty Collection and removes it.
			albumMoverClipboard.delegate?.didAbort()
		}
	}
	
	// This is the same as in CollectionsTVC.
	final override func shouldContinueAfterWillRefreshDataAndViews() -> Bool {
		if albumMoverClipboard != nil {
			return false
		} else {
			return true
		}
	}
	
	// This is the same as in SongsTVC.
	final override func refreshContainers() {
		super.refreshContainers()
		
		refreshNavigationItemTitle()
	}
	
}
