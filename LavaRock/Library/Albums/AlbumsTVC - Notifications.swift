//
//  AlbumsTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-09-03.
//

import UIKit

extension AlbumsTVC {
	// MARK: - Player
	
	final override func reflectPlayer() {
		super.reflectPlayer()
		
		freshenNowPlayingIndicators(accordingTo: self)
	}
	
	// MARK: Library Items
	
	final override func freshenLibraryItems() {
		switch purpose {
		case .organizingAlbums:
			return
		case .movingAlbums:
			return
		case .browsing:
			super.freshenLibraryItems()
		}
	}
}
