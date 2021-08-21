//
//  SongsTVC + NowPlayingIndicatorManager.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

extension SongsTVC: NowPlayingIndicatorManager {
	
	final func isInPlayer(libraryItemFor indexPath: IndexPath) -> Bool {
		if
			let rowSong = viewModel.item(at: indexPath) as? Song,
			rowSong.objectID == PlayerManager.songInPlayer?.objectID
		{
			return true
		} else {
			return false
		}
	}
	
}
