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
			let currentSong = Player.shared.currentSong(context: viewModel.context)
		else {
			return false
		}
		return rowSong.objectID == currentSong.objectID
	}
}
