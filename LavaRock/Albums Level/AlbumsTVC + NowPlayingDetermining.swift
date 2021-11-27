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
			let songInPlayer = PlayerManager.songInPlayer(context: viewModel.context)
		else {
			return false
		}
		
		let result = rowAlbum.objectID == songInPlayer.container?.objectID
		return result
	}
	
}
