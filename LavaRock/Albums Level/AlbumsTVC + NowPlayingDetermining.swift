//
//  AlbumsTVC + NowPlayingDetermining.swift
//  LavaRock
//
//  Created by h on 2020-11-19.
//

import UIKit

extension AlbumsTVC: NowPlayingDetermining {
	
	final func isInPlayer(anyIndexPath: IndexPath) -> Bool {
		if
			let rowAlbum = viewModel.itemOptional(at: anyIndexPath) as? Album,
			rowAlbum.objectID == PlayerManager.songInPlayer?.container?.objectID
		{
			return true
		} else {
			return false
		}
	}
	
}
