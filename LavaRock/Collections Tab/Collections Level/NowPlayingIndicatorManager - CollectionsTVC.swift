//
//  NowPlayingIndicatorManager - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-11-19.
//

import UIKit

extension CollectionsTVC: NowPlayingIndicatorManager {
	
	final func isNowPlayingItem(at indexPath: IndexPath) -> Bool {
		if
			let rowCollection = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as? Collection,
			PlayerControllerManager.shared.currentSong?.container?.container?.objectID == rowCollection.objectID
		{
			return true
		} else {
			return false
		}
	}
	
}
