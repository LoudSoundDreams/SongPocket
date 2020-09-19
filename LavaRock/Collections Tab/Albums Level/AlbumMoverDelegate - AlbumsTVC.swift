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
	
	// Call this from the "move albums" sheet, after completing the animation for inserting the albums we moved. In this object, the non-modal AlbumsTVC, this method removes the albums we just moved. That timing looks good: we remove the albums while dismissing the sheet, so you catch just a glimpse of the albums leaving (even though it's nonsensical).
	// However, that results in "Unbalanced calls to begin/end appearance transitions" for the modal AlbumsTVC, and the non-modal AlbumsTVC unreliably fails to back out, because the non-modal AlbumsTVC finishes removing rows and tries to exit before we've finished dismissing the sheet, which isn't allowed. A hacky workaround for this is to just call refreshDataAndViews() again after completing dismissing the sheet, in didMoveAlbumsThenFinishDismiss(didMakeNewCollection:), below.
	final func didMoveAlbumsThenCommitDismiss() {
		refreshDataAndViews()
	}
	
	final func didMoveAlbumsThenFinishDismiss(didMakeNewCollection: Bool) {
		newCollectionDetector?.shouldDetectNewCollectionsOnNextViewWillAppear = didMakeNewCollection
		refreshDataAndViews() // Exits this collection if it's now empty.
	}
	
}

