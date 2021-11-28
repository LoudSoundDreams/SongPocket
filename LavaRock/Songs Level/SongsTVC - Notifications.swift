//
//  SongsTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit
import CoreData

extension SongsTVC {
	
	// MARK: - After Playback State or "Now Playing" Item Changes
	
	final override func reflectPlayer() {
		super.reflectPlayer()
		
		refreshNowPlayingIndicators(nowPlayingDetermining: self)
	}
	
}
