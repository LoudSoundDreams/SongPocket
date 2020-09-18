//
//  Notifications - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit

extension SongsTVC {
	
	// MARK: - After Possible Playback State Change
	
	override func refreshToReflectPlaybackState() {
		super.refreshToReflectPlaybackState()
		
		refreshCurrentSongIndicator()
	}
	
	private func refreshCurrentSongIndicator() {
		for indexPath in tableView.indexPathsEnumeratedIn(
			section: 0,
			firstRow: numberOfRowsAboveIndexedLibraryItems)
		{
			refreshCurrentSongIndicator(forRowAt: indexPath)
		}
	}
	
	private func refreshCurrentSongIndicator(forRowAt indexPath: IndexPath) {
		let image = currentSongIndicatorImage(forRowAt: indexPath)
		
		if let cell = tableView.cellForRow(at: indexPath) as? SongCell {
			cell.currentSongIndicatorImageView.image = image
		} else if let cell = tableView.cellForRow(at: indexPath) as? SongCellWithDifferentArtist {
			cell.currentSongIndicatorImageView.image = image
		}
	}
	
	// MARK: - Refreshing Data and Views
	
	override func refreshDataAndViews() {
		if areSongActionsPresented {
			dismiss(animated: true, completion: nil)
			areSongActionsPresented = false
		}
		
		super.refreshDataAndViews()
	}
	
	// This is the same as in AlbumsTVC.
	override func refreshContainerOfData() {
		super.refreshContainerOfData()
		
		refreshNavigationItemTitle()
	}
	
}
