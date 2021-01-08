//
//  Notifications - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit
import CoreData

extension SongsTVC {
	
	// MARK: - After Possible Playback State Change
	
	override func refreshToReflectPlaybackState() {
		super.refreshToReflectPlaybackState()
		
		refreshNowPlayingIndicators(isItemNowPlayingDeterminer: isItemNowPlaying(at:))
	}
	
	// MARK: - Refreshing Data and Views
	
	override func prepareToRefreshDataAndViews(
		consideringRefreshedItems refreshedItems: [NSManagedObject]
	) {
		if
			areSongActionsPresented,
			refreshedItems != indexedLibraryItems
		{
			dismiss(animated: true, completion: nil)
			areSongActionsPresented = false
		}
		
		super.prepareToRefreshDataAndViews(
			consideringRefreshedItems: refreshedItems)
	}
	
	// This is the same as in AlbumsTVC.
	override func refreshContainerOfLibraryItems() {
		super.refreshContainerOfLibraryItems()
		
		refreshNavigationItemTitle()
	}
	
}
