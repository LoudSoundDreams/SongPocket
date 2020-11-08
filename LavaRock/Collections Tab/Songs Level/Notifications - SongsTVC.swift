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
		
		refreshNowPlayingIndicators()
	}
	
	private func refreshNowPlayingIndicators() {
		for indexPath in tableView.indexPathsEnumeratedIn(
			section: 0,
			firstRow: numberOfRowsAboveIndexedLibraryItems)
		{
			guard var cell = tableView.cellForRow(at: indexPath) as? NowPlayingIndicator else { continue }
			cell.apply(nowPlayingIndicator: nowPlayingIndicator(forRowAt: indexPath))
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
