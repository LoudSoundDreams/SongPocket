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
	
	final func didMoveAlbums(didMakeNewCollection: Bool) {
		newCollectionDetector?.shouldDetectNewCollectionsOnNextViewWillAppear = didMakeNewCollection
		refreshDataAndViews()
	}
	
}

