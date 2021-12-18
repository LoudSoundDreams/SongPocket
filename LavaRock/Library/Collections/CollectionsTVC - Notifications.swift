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
	@objc private func userDidUpdateDatabase() { reflectDatabase() }
	
	// MARK: - After Playback State or "Now Playing" Item Changes
	
	final override func reflectPlayer() {
		super.reflectPlayer()
		
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
				revertCombine(thenSelect: [])
			}
			
			super.refreshLibraryItems()
		}
	}
	
}
