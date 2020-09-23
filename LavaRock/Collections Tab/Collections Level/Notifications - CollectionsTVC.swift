//
//  Notifications - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// MARK: - Refreshing Data and Views
	
	override func prepareToRefreshDataAndViews(
		consideringRefreshedItems refreshedItems: [NSManagedObject]
	) {
		if let albumMoverClipboard = albumMoverClipboard {
			// What if any of the albums we're moving get deleted?
			
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
				// Calling didAbort() solves the case where, when we had to refresh, you were moving albums, had the "New Collection" dialog onscreen, *and* deleted all the albums in the collection that you were moving albums out of: we'll dismiss the "New Collection" dialog, dismiss the "move albums" sheet, back out of the now-empty collection, and delete that empty collection.
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
