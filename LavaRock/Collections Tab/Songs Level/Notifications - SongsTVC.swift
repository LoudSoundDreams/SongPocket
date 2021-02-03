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
	
	final override func refreshToReflectPlaybackState() {
		super.refreshToReflectPlaybackState()
		
		refreshNowPlayingIndicators(isItemNowPlayingDeterminer: isItemNowPlaying(at:))
	}
	
	// MARK: - Refreshing Data and Views
	
	final override func willRefreshDataAndViews(
		toShow refreshedItems: [NSManagedObject]
	) {
		if
			areSongActionsPresented,
			refreshedItems != indexedLibraryItems
		{
			dismiss(animated: true, completion: nil)
			areSongActionsPresented = false
		}
		
		super.willRefreshDataAndViews(
			toShow: refreshedItems)
	}
	
	// This is the same as in AlbumsTVC.
	final override func refreshContainerOfLibraryItems() {
		super.refreshContainerOfLibraryItems()
		
		refreshNavigationItemTitle()
	}
	
}
