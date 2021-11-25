//
//  SongsTVC + NowPlayingDetermining.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

extension SongsTVC: NowPlayingDetermining {
	
	final func isInPlayer(anyIndexPath: IndexPath) -> Bool {
		if
			let rowSong = viewModel.itemOptional(at: anyIndexPath) as? Song,
			rowSong.objectID == PlayerManager.songInPlayer?.objectID
		{
			return true
		} else {
			return false
		}
	}
	
}
