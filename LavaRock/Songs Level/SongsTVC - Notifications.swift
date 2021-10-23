//
//  SongsTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit
import CoreData

extension SongsTVC {
	
	// MARK: - After Possible Playback State Change
	
	final override func reflectPlaybackStateAndNowPlayingItem() {
		super.reflectPlaybackStateAndNowPlayingItem()
		
		refreshNowPlayingIndicators(nowPlayingDetermining: self)
	}
	
}
