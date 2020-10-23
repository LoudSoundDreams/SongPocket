//
//  Notifications - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit
import CoreData

extension SongsTVC {
	
	// MARK: - After Possible Playback State Change
	
	override func refreshToReflectPlaybackState() {
		super.refreshToReflectPlaybackState()
		
		refreshCurrentSongStatus()
	}
	
	private func refreshCurrentSongStatus() {
		for indexPath in tableView.indexPathsEnumeratedIn(
			section: 0,
			firstRow: numberOfRowsAboveIndexedLibraryItems)
		{
			refreshCurrentSongStatus(forRowAt: indexPath)
		}
	}
	
	private func refreshCurrentSongStatus(forRowAt indexPath: IndexPath) {
		let currentSongStatus = currentSongStatusImageAndAccessibilityLabel(forRowAt: indexPath)
		let image = currentSongStatus.0
		let accessibilityLabel = currentSongStatus.1
		
		if let cell = tableView.cellForRow(at: indexPath) as? SongCell {
			cell.currentSongStatusImageView.image = image
			cell.accessibilityValue = accessibilityLabel
		} else if let cell = tableView.cellForRow(at: indexPath) as? SongCellWithDifferentArtist {
			cell.currentSongStatusImageView.image = image
			cell.accessibilityValue = accessibilityLabel
		}
	}
	
	// MARK: - Refreshing Data and Views
	
	override func prepareToRefreshDataAndViews(
		consideringRefreshedItems refreshedItems: [NSManagedObject]
	) {
		if
			areSongActionsPresented,
			refreshedItems != indexedLibraryItems
		{
			dismiss(animated: true, completion: nil)
			areSongActionsPresented = false
		}
		
		super.prepareToRefreshDataAndViews(
			consideringRefreshedItems: refreshedItems)
	}
	
	// This is the same as in AlbumsTVC.
	override func refreshContainerOfData() {
		super.refreshContainerOfData()
		
		refreshNavigationItemTitle()
	}
	
}
