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
	
	final override func reflectPlayer() {
		super.reflectPlayer()
		
		refreshNowPlayingIndicators(nowPlayingDetermining: self)
	}
	
	// MARK: - Refreshing Library Items
	
	final override func refreshLibraryItems() {
		switch purpose {
		case .organizingAlbums:
			break
		case .movingAlbums:
			break
		case .browsing:
			super.refreshLibraryItems()
		}
	}
	
}
