//
//  AlbumsTVC + AlbumMoverDelegate.swift
//  LavaRock
//
//  Created by h on 2020-09-16.
//

import UIKit

extension AlbumsTVC: AlbumMoverDelegate {
	
	// Similar to LibraryTVC.refreshLibraryItemsPart2.
	// Call this from the modal AlbumsTVC in the "move Albums to…" sheet after completing the animation for inserting the Albums we moved. This instance here, the non-modal AlbumsTVC, should be the modal AlbumsTVC's delegate, and this method removes the rows for those Albums.
	// That timing looks good: we remove the Albums while dismissing the sheet, so you catch just a glimpse of the Albums disappearing, even though it technically doesn't make sense.
	final func didMoveAlbumsThenCommitDismiss() {
		let newItemsAndSections = viewModel.newItemsAndSections()
		newItemsAndSections.forEach { (newItems, section) in
			setItemsAndRefresh(
				newItems: newItems,
				section: section)
		}
	}
	
}

