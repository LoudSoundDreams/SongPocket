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
	
	// MARK: - Refreshing Data and Views
	
	final override func refreshDataAndViews() {
		if albumMoverClipboard != nil {
		} else {
			deleteAllRowsIfFinishedLoading()
			
			if previousSectionOfCollections != nil { // If the "Combine Collections" dialog is presented.
				fatalError()
				
//				dismiss(animated: false) { //
//					print("Dismissed “Combine Collections” dialog.")
//					self.revertCombineCollections {
//						print("Refreshing data and views.")
//						super.refreshDataAndViews()
//					}
//				}
			} else {
				super.refreshDataAndViews()
			}
		}
	}
	
}
