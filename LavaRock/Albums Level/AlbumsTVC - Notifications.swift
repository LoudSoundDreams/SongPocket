//
//  AlbumsTVC - Notifications.swift
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
		
		refreshNowPlayingIndicators(isInPlayerDeterminer: isInPlayer(libraryItemFor:))
	}
	
	// MARK: - Refreshing Library Items
	
	final override func refreshLibraryItems() {
		if albumMoverClipboard != nil {
		} else {
			super.refreshLibraryItems()
		}
	}
	
}
