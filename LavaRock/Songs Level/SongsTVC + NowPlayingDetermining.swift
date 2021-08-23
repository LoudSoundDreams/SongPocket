//
//  SongsTVC + NowPlayingDetermining.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

extension SongsTVC: NowPlayingDetermining {
	
	final func isInPlayer(libraryItemAt indexPath: IndexPath) -> Bool {
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
