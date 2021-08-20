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
	
	// MARK: - Refreshing Library Items
	
	final override func refreshLibraryItems() {
		if albumMoverClipboard != nil {
		} else {
			prepareToRefreshLibraryItems()
			
			if isPreviewingCombineCollections() {
				fatalError()
				
				
//				print("Reverting “Combine Collections”.")
//				revertCombineCollections(
//					from: [] //
//				) {
//					print("Reverted. Refreshing library items.")
//					super.refreshLibraryItems()
//				}
			} else {
				super.refreshLibraryItems()
			}
		}
	}
	
}
