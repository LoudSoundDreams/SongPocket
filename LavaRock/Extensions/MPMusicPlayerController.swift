//
//  MPMusicPlayerController.swift
//  LavaRock
//
//  Created by h on 2022-03-19.
//

import MediaPlayer
import os

@MainActor
extension MPMusicPlayerController {
	private var signposter: OSSignposter {
		.mediaPlayer
	}
	
	final func playNow(
		_ mediaItems: [MPMediaItem],
		new_repeat_mode: MPMusicRepeatMode,
		disable_shuffle: Bool
	) {
		if Enabling.console {
			Reel.setMediaItems(mediaItems)
		}
		
		let setQueueInterval = signposter.beginInterval("set queue")
		setQueue(mediaItems: mediaItems)
		signposter.endInterval("set queue", setQueueInterval)
		
		// As of iOS 15.6 RC 2, with `systemMusicPlayer`, you must set these after calling `setQueue`, not before, or they won’t actually apply.
		repeatMode = new_repeat_mode
		if disable_shuffle {
			shuffleMode = .off
		}
		
		let playInterval = signposter.beginInterval("play")
		play()
		signposter.endInterval("play", playInterval)
	}
	
	final func playNext(_ mediaItems: [MPMediaItem]) {
		if Enabling.console {
			if Reel.mediaItems.isEmpty {
				Reel.setMediaItems(mediaItems)
				
				setQueue(mediaItems: mediaItems)
			} else {
				Reel.setMediaItems({
					var newMediaItems = Reel.mediaItems
					newMediaItems.insert(
						contentsOf: mediaItems,
						at: indexOfNowPlayingItem + 1)
					return newMediaItems
				}())
				
				prepend(mediaItems)
			}
		} else {
			prepend(mediaItems)
		}
		
		if Enabling.console {
		} else {
			repeatMode = .none
		}
		
		// TO DO: Do we need this? (See `playLast`)
		if playbackState != .playing {
			prepareToPlay()
		}
	}
	
	final func playLast(_ mediaItems: [MPMediaItem]) {
		if Enabling.console {
			if Reel.mediaItems.isEmpty {
				// This is a workaround. As of iOS 15.4, when the queue is empty, `append` does nothing.
				Reel.setMediaItems(mediaItems)
				
				setQueue(mediaItems: mediaItems)
			} else {
				Reel.setMediaItems({
					var newMediaItems = Reel.mediaItems
					newMediaItems.append(contentsOf: mediaItems)
					return newMediaItems
				}())
				
				append(mediaItems)
			}
		} else {
			// As of iOS 15.4, when using `MPMusicPlayerController.systemMusicPlayer` and the queue is empty, this does nothing, but I can’t find a workaround.
			append(mediaItems)
		}
		
		if Enabling.console {
		} else {
			repeatMode = .none
		}
		
		// As of iOS 14.7 developer beta 1, you must do this in case the user force quit the built-in Music app recently.
		if playbackState != .playing {
			prepareToPlay()
		}
	}
	
	private func setQueue(mediaItems: [MPMediaItem]) {
		setQueue(with: MPMediaItemCollection(items: mediaItems))
	}
	private func prepend(_ mediaItems: [MPMediaItem]) {
		prepend(MPMusicPlayerMediaItemQueueDescriptor(
			itemCollection: MPMediaItemCollection(items: mediaItems)))
	}
	private func append(_ mediaItems: [MPMediaItem]) {
		append(MPMusicPlayerMediaItemQueueDescriptor(
			itemCollection: MPMediaItemCollection(items: mediaItems)))
	}
}
