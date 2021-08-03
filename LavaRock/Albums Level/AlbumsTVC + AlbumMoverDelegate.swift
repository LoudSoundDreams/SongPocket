//
//  AlbumsTVC + AlbumMoverDelegate.swift
//  LavaRock
//
//  Created by h on 2020-09-16.
//

import UIKit

extension AlbumsTVC: AlbumMoverDelegate {
	
	// Call this from the "move Albums to…" sheet after completing the animation for inserting the Albums we moved. Here, in the non-modal AlbumsTVC, this method removes the rows for those Albums.
	// That timing looks good: we remove the Albums while dismissing the sheet, so you catch just a glimpse of the Albums disappearing, even though it technically doesn't make sense.
	final func didMoveAlbumsThenCommitDismiss() {
		let newItems = sectionOfLibraryItems.itemsFetched(via: managedObjectContext)
		setItemsAndRefreshToMatch(newItems: newItems)
	}
	
}

