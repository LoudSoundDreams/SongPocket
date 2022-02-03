//
//  CollectionsViewModel + NowPlayingDetermining.swift
//  LavaRock
//
//  Created by h on 2021-08-22.
//

import UIKit

extension CollectionsViewModel: NowPlayingDetermining {
	func isInPlayer(anyIndexPath: IndexPath) -> Bool {
		guard
			let rowCollection = itemOptional(at: anyIndexPath) as? Collection,
			let songInPlayer = SharedPlayer.songInPlayer(context: context)
		else {
			return false
		}
		
		let result = rowCollection.objectID == songInPlayer.container?.container?.objectID
		return result
	}
}
