//
//  AlbumMoverDelegate - AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-16.
//

import UIKit

extension AlbumsTVC: AlbumMoverDelegate {
	
	final func didAbort() {
		refreshDataAndViews()
	}
	
	// Call this from the "move Albums" sheet, after completing the animation for inserting the Albums we moved. In this instance, the non-modal AlbumsTVC, this method removes the Albums we just moved. That timing looks good: we remove the Albums while dismissing the sheet, so you catch just a glimpse of the Albums leaving (even though it's nonsensical).
	// However, that results in "Unbalanced calls to begin/end appearance transitions" for the modal AlbumsTVC, and the non-modal AlbumsTVC unreliably fails to back out, because the non-modal AlbumsTVC finishes removing rows and tries to exit before we've finished dismissing the sheet, which isn't allowed. A hacky workaround for this is to just call refreshDataAndViews() again after completing dismissing the sheet, in didMoveAlbumsThenFinishDismiss(didMakeNewCollection:), below.
	final func didMoveAlbumsThenCommitDismiss() {
		refreshDataAndViews()
	}
	
	final func didMoveAlbumsThenFinishDismiss(didMakeNewCollection: Bool) {
		newCollectionDetector?.shouldDetectNewCollectionsOnNextViewWillAppear = didMakeNewCollection
		refreshDataAndViews() // Exits this Collection if it's now empty.
	}
	
}

