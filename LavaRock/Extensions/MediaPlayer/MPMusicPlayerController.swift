//
//  MPMusicPlayerController.swift
//  LavaRock
//
//  Created by h on 2022-03-19.
//

import MediaPlayer

extension MPMusicPlayerController {
	func setQueue(with songs: [Song]) {
		setQueue(
			with: MPMediaItemCollection(
				items: songs.compactMap { $0.mpMediaItem() }))
	}
	
	func appendToQueue(_ songs: [Song]) {
		append(
			MPMusicPlayerMediaItemQueueDescriptor(
				itemCollection: MPMediaItemCollection(
					items: songs.compactMap { $0.mpMediaItem() })))
	}
}
