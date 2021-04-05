//
//  NowPlayingIndicatorManager - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

extension SongsTVC: NowPlayingIndicatorManager {
	
	final func isItemNowPlaying(at indexPath: IndexPath) -> Bool {
		if
			let rowSong = libraryItem(for: indexPath) as? Song,
			let rowMediaItem = rowSong.mpMediaItem(),
			let playerController = sharedPlayerController,
			rowMediaItem == playerController.nowPlayingItem
		{
			return true
		} else {
			return false
		}
	}
	
}
