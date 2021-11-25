//
//  CollectionsViewModel + NowPlayingDetermining.swift
//  LavaRock
//
//  Created by h on 2021-08-22.
//

import UIKit

extension CollectionsViewModel: NowPlayingDetermining {
	
	func isInPlayer(anyIndexPath: IndexPath) -> Bool {
		if
			let rowCollection = itemOptional(at: anyIndexPath) as? Collection,
			rowCollection.objectID == PlayerManager.songInPlayer?.container?.container?.objectID
		{
			return true
		} else {
			return false
		}
	}
	
}
