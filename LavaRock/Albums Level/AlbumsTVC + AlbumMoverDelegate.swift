//
//  AlbumsTVC + AlbumMoverDelegate.swift
//  LavaRock
//
//  Created by h on 2020-09-16.
//

import UIKit

extension AlbumsTVC: AlbumMoverDelegate {
	
	// Call this from the "move Albums to…" sheet after completing the animation for inserting the Albums we moved. Here, in the non-modal AlbumsTVC, this method removes the rows for the Albums we just moved. (That timing looks good: we remove the Albums while dismissing the sheet, so you catch just a glimpse of the Albums leaving (even though it technically doesn't make sense).)
	// However, we then (sometimes) fail to back out of the non-modal AlbumsTVC, because it can finish removing rows and try to exit before we've finished dismissing the "move Albums to…" sheet, which isn't allowed. A simple workaround for this is to just refresh the table view again after completing dismissing the sheet, in didMoveAlbumsThenFinishDismiss, below.
	final func didMoveAlbumsThenCommitDismiss() {
		let newItems = sectionOfLibraryItems.fetchedItems()
		setItemsAndRefreshTableView(
			newItems: newItems,
			completion: nil)
	}
	
	final func didMoveAlbumsThenFinishDismiss() {
		NotificationCenter.default.post(
			Notification(name: .LRDidMoveAlbums)
		)
		let existingItems = sectionOfLibraryItems.items
		setItemsAndRefreshTableView( // Exits this Collection if it's now empty.
			newItems: existingItems,
			completion: nil)
	}
	
}

