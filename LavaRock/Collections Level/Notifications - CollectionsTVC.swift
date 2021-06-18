//
//  Notifications - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// MARK: - Setup
	
	final override func beginObservingNotifications() {
		super.beginObservingNotifications()
		
		if albumMoverClipboard != nil {
		} else {
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(didObserveLRDidMoveAlbums),
				name: Notification.Name.LRDidMoveAlbums,
				object: nil)
		}
	}
	
	// MARK: - After Moving Albums
	
	@objc private func didObserveLRDidMoveAlbums() {
		didMoveAlbums = true
	}
	
	// MARK: - After Possible Playback State Change
	
	final override func refreshToReflectPlaybackState() {
		super.refreshToReflectPlaybackState()
		
		refreshNowPlayingIndicators(isInPlayerDeterminer: isInPlayer(libraryItemFor:))
	}
	
	// MARK: - Refreshing Data and Views
	
	/*
	When moving Albums:
	- What if any of the Albums we're moving get deleted?
	- What if we've already made a new Collection and are transitioning into or out of it?
	Currently, we're just dismissing the "move Albums" sheet to not deal with any of those edge cases.
	*/
	
	final override func refreshDataAndViews() {
		if albumMoverClipboard != nil {
			return // without refreshing
		}
		
		if isLoading {
			didJustFinishLoading = true
			// contentState() is now .justFinishedLoading
			refreshToReflectContentState(completion: nil)
			didJustFinishLoading = false
		}
		
		super.refreshDataAndViews()
	}
	
}
