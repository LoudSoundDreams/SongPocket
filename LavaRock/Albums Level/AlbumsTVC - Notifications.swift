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
	
	// MARK: - Refreshing Data and Views
	
	final override func refreshDataAndViews() {
		if albumMoverClipboard != nil {
		} else {
			super.refreshDataAndViews()
		}
	}
	
}
