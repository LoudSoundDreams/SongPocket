//
//  MPMusicPlayerController.swift
//  LavaRock
//
//  Created by h on 2022-03-19.
//

import MediaPlayer

extension MPMusicPlayerController {
	final func play(_ songs: [Song]) {
		if Enabling.playerScreen {
			SongQueue.setContents(songs)
		}
		setQueue(
			with: MPMediaItemCollection(
				items: songs.compactMap { $0.mpMediaItem() }))
		
		// As of iOS 14.7 developer beta 1, you must set these after calling `setQueue`, not before, or they won’t actually apply.
		repeatMode = .none
		shuffleMode = .off
		
		play() // Calls `prepareToPlay` automatically
	}
}
