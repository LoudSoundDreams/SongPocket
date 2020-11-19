//
//  NowPlayingIndicatorManager - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

extension SongsTVC: NowPlayingIndicatorManager {
	
	final func isNowPlayingItem(at indexPath: IndexPath) -> Bool {
		if
			let rowSong = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as? Song,
			let rowMediaItem = rowSong.mpMediaItem(),
			let playerController = playerController,
			rowMediaItem == playerController.nowPlayingItem
		{
			return true
		} else {
			return false
		}
	}
	
}
