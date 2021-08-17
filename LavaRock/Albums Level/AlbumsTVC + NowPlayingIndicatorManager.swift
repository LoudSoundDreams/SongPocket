//
//  AlbumsTVC + NowPlayingIndicatorManager.swift
//  LavaRock
//
//  Created by h on 2020-11-19.
//

import UIKit

extension AlbumsTVC: NowPlayingIndicatorManager {
	
	final func isInPlayer(libraryItemFor indexPath: IndexPath) -> Bool {
		if
			let rowAlbum = viewModel.item(for: indexPath) as? Album,
			rowAlbum.objectID == PlayerManager.songInPlayer?.container?.objectID
		{
			return true
		} else {
			return false
		}
	}
	
}
