//
//  CollectionsTVC - Notifications.swift
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
		
		switch purpose {
		case .organizingAlbums:
			break
		case .movingAlbums:
			break
		case .browsing:
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(userDidUpdateDatabase),
				name: .LRUserDidUpdateDatabase,
				object: nil)
		}
	}
	
	// MARK: - After Moving Albums
	
	// TO DO: Obviate this.
	@objc private func userDidUpdateDatabase() {
		needsReflectDatabase = true
	}
	
	// MARK: - After Playback State or "Now Playing" Item Changes
	
	final override func reflectPlaybackStateAndNowPlayingItem() {
		super.reflectPlaybackStateAndNowPlayingItem()
		
		if let viewModel = viewModel as? NowPlayingDetermining {
			refreshNowPlayingIndicators(nowPlayingDetermining: viewModel)
		}
	}
	
	// MARK: - Refreshing Library Items
	
	final override func refreshLibraryItems() {
		switch purpose {
		case .organizingAlbums:
			break
		case .movingAlbums:
			break
		case .browsing:
			willRefreshLibraryItems()
			
			if viewModelBeforeCombining != nil {
				revertCombine(andSelectRowsAt: [])
			}
			
			super.refreshLibraryItems()
		}
	}
	
}
