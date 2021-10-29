//
//  AlbumsTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-09-03.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// MARK: - After Playback State or "Now Playing" Item Changes
	
	final override func reflectPlaybackStateAndNowPlayingItem() {
		super.reflectPlaybackStateAndNowPlayingItem()
		
		refreshNowPlayingIndicators(nowPlayingDetermining: self)
	}
	
	// MARK: - Refreshing Library Items
	
	final override func refreshLibraryItems() {
		if albumMoverClipboard != nil {
		} else {
			super.refreshLibraryItems()
		}
	}
	
}
