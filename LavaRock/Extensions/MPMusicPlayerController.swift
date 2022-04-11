//
//  MPMusicPlayerController.swift
//  LavaRock
//
//  Created by h on 2022-03-19.
//

import MediaPlayer

extension MPMusicPlayerController {
	private func setQueue(with songs: [Song]) {
		setQueue(
			with: MPMediaItemCollection(
				items: songs.compactMap { $0.mpMediaItem() }))
	}
	private func prepend(_ songs: [Song]) {
		prepend(MPMusicPlayerMediaItemQueueDescriptor(
			itemCollection: MPMediaItemCollection(
				items: songs.compactMap { $0.mpMediaItem() })))
	}
	private func append(_ songs: [Song]) {
		append(
			MPMusicPlayerMediaItemQueueDescriptor(
				itemCollection: MPMediaItemCollection(
					items: songs.compactMap { $0.mpMediaItem() })))
	}
	
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
	
	final func playNext(_ songs: [Song]) {
		if Enabling.playerScreen {
			if SongQueue.contents.isEmpty {
				// This is a workaround. As of iOS 15.4, when the queue is empty, `append` does nothing.
				SongQueue.setContents(songs)
				
				setQueue(with: songs)
			} else {
				var newContents = SongQueue.contents
				newContents.insert(
					contentsOf: songs,
					at: indexOfNowPlayingItem + 1) // TO DO
				SongQueue.setContents(newContents)
				
				prepend(songs)
			}
		} else {
			prepend(songs)
		}
		
		if Enabling.playerScreen {
		} else {
			repeatMode = .none
		}
		
		// TO DO: Do we need this? (See `playLast`)
		if playbackState != .playing {
			prepareToPlay()
		}
	}
	
	final func playLast(_ songs: [Song]) {
		if Enabling.playerScreen {
			if SongQueue.contents.isEmpty {
				// This is a workaround. As of iOS 15.4, when the queue is empty, `append` does nothing.
				SongQueue.setContents(songs)
				
				setQueue(with: songs)
			} else {
				var newContents = SongQueue.contents
				newContents.append(contentsOf: songs)
				SongQueue.setContents(newContents)
				
				append(songs)
			}
		} else {
			// As of iOS 15.4, when using `MPMusicPlayerController.systemMusicPlayer` and the queue is empty, this does nothing, but I can’t find a workaround.
			append(songs)
		}
		
		if Enabling.playerScreen {
		} else {
			repeatMode = .none
		}
		
		// As of iOS 14.7 developer beta 1, you must do this in case the user force quit the built-in Music app recently.
		if playbackState != .playing {
			prepareToPlay()
		}
	}
}
