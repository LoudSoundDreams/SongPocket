//
//  Notifications - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit

extension CollectionsTVC {
	
	// MARK: - Refreshing Data and Views
	
	override func refreshDataAndViews() {
		if let albumMoverClipboard = albumMoverClipboard {
			if albumMoverClipboard.isMakingNewCollection {
				albumMoverClipboard.isMakingNewCollection = false
				dismiss(animated: true, completion: refreshDataAndViews) // Dismisses presentedViewController, the "New Collection" dialog.
			} else {
				dismiss(animated: true, completion: albumMoverClipboard.delegate?.didAbort) // Tells presentingViewController to dismiss this view controller (CollectionsTVC).
				// Calling didAbort() solves the case where, when we had to refresh, you were moving albums, had the "New Collection" dialog onscreen, *and* deleted all the albums in the collection that you were moving albums out of: we'll dismiss the "New Collection" dialog, dismiss the "move albums" sheet, back out of the now-empty collection, and delete that empty collection.
			}
			return
			
		} else if isRenamingCollection {
			dismiss(animated: true, completion: nil)
			isRenamingCollection = false
			
		}
		
		super.refreshDataAndViews()
	}
	
}
