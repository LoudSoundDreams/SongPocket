//
//  MPMusicPlayerController.swift
//  LavaRock
//
//  Created by h on 2022-03-19.
//

import MediaPlayer

extension MPMusicPlayerController {
	final func playNow(_ songs: [Song]) {
		if Enabling.playerScreen {
			SongQueue.setContents(songs)
		}
		setQueue(with: songs)
		
		// As of iOS 14.7 developer beta 1, you must set these after calling `setQueue`, not before, or they won’t actually apply.
		repeatMode = .none
		shuffleMode = .off
		
		play() // Calls `prepareToPlay` automatically
	}
	
	final func playLast(_ songs: [Song]) {
		if Enabling.playerScreen {
			if SongQueue.contents.isEmpty {
				// This is a workaround. As of iOS 15.4, when the queue is empty, `append` does nothing.
				SongQueue.setContents(songs)
				setQueue(with: songs)
			} else {
				SongQueue.append(contentsOf: songs)
				append(songs)
			}
		} else {
			// As of iOS 15.4, when using `MPMusicPlayerController.systemMusicPlayer` and the queue is empty, this does nothing, but I can’t find a workaround.
			append(songs)
		}
		
		repeatMode = .none
		
		// As of iOS 14.7 developer beta 1, you must do this in case the user force quit the built-in Music app recently.
		if playbackState != .playing {
			prepareToPlay()
		}
	}
	
	private func setQueue(with songs: [Song]) {
		setQueue(
			with: MPMediaItemCollection(
				items: songs.compactMap { $0.mpMediaItem() }))
	}
	
	private func append(_ songs: [Song]) {
		append(
			MPMusicPlayerMediaItemQueueDescriptor(
				itemCollection: MPMediaItemCollection(
					items: songs.compactMap { $0.mpMediaItem() })))
	}
}
