//
//  Notifications - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// MARK: - After Possible Playback State Change
	
	final override func refreshToReflectPlaybackState() {
		super.refreshToReflectPlaybackState()
		
		refreshNowPlayingIndicators(isItemNowPlayingDeterminer: isItemNowPlaying(at:))
	}
	
	// MARK: - Refreshing Data and Views
	
	final override func prepareToRefreshDataAndViews(
		consideringRefreshedItems refreshedItems: [NSManagedObject]
	) {
		if let albumMoverClipboard = albumMoverClipboard {
			// What if any of the Albums we're moving get deleted?
			
			// What if we've already made a new Collection and are transitioning into or out of it?
			
			if albumMoverClipboard.isMakingNewCollection {
				albumMoverClipboard.isMakingNewCollection = false
				// Only do this if indexedLibraryItems will change during the refresh?
				dismiss(animated: true, completion: { // Dismisses presentedViewController, the "New Collection" dialog.
					self.prepareToRefreshDataAndViews(
						consideringRefreshedItems: refreshedItems)
				} )
			} else {
				// Only do this if indexedLibraryItems will change during the refresh?
				dismiss(animated: true, completion: albumMoverClipboard.delegate?.didAbort) // Tells presentingViewController to dismiss this view controller (CollectionsTVC).
				// Calling didAbort() solves the case where, before the refresh, you were moving Albums, had the "New Collection" dialog onscreen, *and* deleted all the Albums in the Collection that you were moving Albums out of: we'll dismiss the "New Collection" dialog, dismiss the "move Albums" sheet, back out of the now-empty Collection, and delete that empty Collection.
			}
		}
		
		if
			isRenamingCollection,
			refreshedItems != indexedLibraryItems
		{
			dismiss(animated: true, completion: nil)
			isRenamingCollection = false
		}
		
		super.prepareToRefreshDataAndViews(consideringRefreshedItems: refreshedItems)
	}
	
}
