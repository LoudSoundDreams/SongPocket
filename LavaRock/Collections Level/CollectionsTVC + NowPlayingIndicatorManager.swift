//
//  CollectionsTVC + NowPlayingIndicatorManager.swift
//  LavaRock
//
//  Created by h on 2020-11-19.
//

import UIKit

extension CollectionsTVC: NowPlayingIndicatorManager {
	
	final func isInPlayer(libraryItemFor indexPath: IndexPath) -> Bool {
		if
			let rowCollection = viewModel.item(at: indexPath) as? Collection,
			rowCollection.objectID == PlayerManager.songInPlayer?.container?.container?.objectID
		{
			return true
		} else {
			return false
		}
	}
	
}
