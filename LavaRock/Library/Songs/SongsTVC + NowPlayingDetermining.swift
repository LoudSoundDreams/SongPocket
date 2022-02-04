//
//  SongsTVC + NowPlayingDetermining.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

extension SongsTVC: NowPlayingDetermining {
	final func isInPlayer(anyIndexPath: IndexPath) -> Bool {
		guard
			let rowSong = viewModel.itemOptional(at: anyIndexPath) as? Song,
			let songInPlayer = SharedPlayer.songInPlayer(context: viewModel.context)
		else {
			return false
		}
		return rowSong.objectID == songInPlayer.objectID
	}
}
