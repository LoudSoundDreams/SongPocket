//
//  AlbumsTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-09-03.
//

import UIKit
import CoreData

extension AlbumsTVC {
	// MARK: - Player
	
	final override func reflectPlayer() {
		super.reflectPlayer()
		
		refreshNowPlayingIndicators(nowPlayingDetermining: self)
	}
	
	// MARK: Library Items
	
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
