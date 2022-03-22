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
			let currentSong = Player.shared.currentSong(context: context)
		else {
			return false
		}
		return rowCollection.objectID == currentSong.container?.container?.objectID
	}
}
