//
//  Notifications - AlbumsTVC.swift
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
	
	/*
	All special cases in AlbumsTVC:
	- In "moving Albums" mode and in existing Collection
	- In "moving Albums" mode and in new Collection
	- If any of the Albums we're moving get deleted
	*/
	
	final override func refreshDataAndViews() {
		if albumMoverClipboard != nil {
			return // without refreshing
		}
		
		super.refreshDataAndViews()
	}
	
}
