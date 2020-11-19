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
	
	override func refreshToReflectPlaybackState() {
		super.refreshToReflectPlaybackState()
		
		refreshNowPlayingIndicators(isNowPlayingItemDeterminer: isNowPlayingItem(at:))
	}
	
	// MARK: - Refreshing Data and Views
	
	override func prepareToRefreshDataAndViews(
		consideringRefreshedItems refreshedItems: [NSManagedObject]
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
		
		super.prepareToRefreshDataAndViews(
			consideringRefreshedItems: refreshedItems)
	}
	
	// This is the same as in SongsTVC.
	override func refreshContainerOfData() {
		super.refreshContainerOfData()
		
		refreshNavigationItemTitle()
	}
	
}
