//
//  AlbumsTVC + NowPlayingDetermining.swift
//  LavaRock
//
//  Created by h on 2020-11-19.
//

import UIKit

extension AlbumsTVC: NowPlayingDetermining {
	final func isInPlayer(anyIndexPath: IndexPath) -> Bool {
		guard
			let rowAlbum = viewModel.itemOptional(at: anyIndexPath) as? Album,
			let currentSong = Player.shared.currentSong(context: viewModel.context)
		else {
			return false
		}
		return rowAlbum.objectID == currentSong.container?.objectID
	}
}
