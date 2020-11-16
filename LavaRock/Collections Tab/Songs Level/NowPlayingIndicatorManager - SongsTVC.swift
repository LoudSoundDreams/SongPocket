//
//  NowPlayingIndicatorManager - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

extension SongsTVC: NowPlayingIndicatorManager {
	
	final func nowPlayingIndicator(forRowAt indexPath: IndexPath) -> (UIImage?, String?) {
		if
			let rowSong = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as? Song,
			let rowMediaItem = rowSong.mpMediaItem(),
			let playerController = playerController,
			rowMediaItem == playerController.nowPlayingItem
		{
			if playerController.playbackState == .playing { // There are many playback states; only show the "playing" icon when the player controller is playing. Otherwise, show the "not playing" icon.
				if #available(iOS 14.0, *) {
					return (
						UIImage(systemName: "speaker.wave.2.fill"),
						"Now playing")
				} else { // iOS 13
					return (
						UIImage(systemName: "speaker.2.fill"),
						"Now playing")
				}
			} else {
				return (
					UIImage(systemName: "speaker.fill"),
					"Paused")
			}
		} else {
			return (nil, nil)
		}
	}
	
}
