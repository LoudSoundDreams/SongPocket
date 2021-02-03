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
	
	final override func willRefreshDataAndViews(
		toShow refreshedItems: [NSManagedObject]
	) {
		if albumMoverClipboard != nil {
			/*
			Only do this if indexedLibraryItems will change during the refresh?
			
			All special cases:
			- In "moving Albums" mode and in existing Collection
			- In "moving Albums" mode and in new Collection
			- If any of the Albums we're moving get deleted
			*/
			dismiss(animated: true, completion: nil)
		}
		
		super.willRefreshDataAndViews(
			toShow: refreshedItems)
	}
	
	// This is the same as in SongsTVC.
	final override func refreshContainerOfLibraryItems() {
		super.refreshContainerOfLibraryItems()
		
		refreshNavigationItemTitle()
	}
	
}
