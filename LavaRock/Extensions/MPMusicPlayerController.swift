//
//  MPMusicPlayerController.swift
//  LavaRock
//
//  Created by h on 2022-03-19.
//

import MediaPlayer
import OSLog

@MainActor
extension MPMusicPlayerController {
	private static var signposter = OSSignposter(
		subsystem: "MPMusicPlayerController",
		category: .pointsOfInterest)
	
	final func currentSongID() -> SongID? {
#if targetEnvironment(simulator)
		return Sim_Global.songID
#else
		guard let nowPlayingItem else {
			return nil
		}
		return SongID(bitPattern: nowPlayingItem.persistentID)
#endif
	}
	
	final func playNow(
		_ mediaItems: [MPMediaItem],
		new_repeat_mode: MPMusicRepeatMode,
		disable_shuffle: Bool
	) {
		if Enabling.inAppPlayer {
			Reel.setMediaItems(mediaItems)
		}
		
		let setQueueInterval = Self.signposter.beginInterval("set queue")
		setQueue(mediaItems: mediaItems)
		Self.signposter.endInterval("set queue", setQueueInterval)
		
		// As of iOS 15.6 RC 2, with `systemMusicPlayer`, you must set these after calling `setQueue`, not before, or they won’t actually apply.
		repeatMode = new_repeat_mode
		if disable_shuffle {
			shuffleMode = .off
		}
		
		let playInterval = Self.signposter.beginInterval("play")
		play()
		Self.signposter.endInterval("play", playInterval)
	}
	
	final func playNext(_ mediaItems: [MPMediaItem]) {
		if Enabling.inAppPlayer {
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
		
		// TO DO: Do we need this? (See `playLast`)
		if playbackState != .playing {
			prepareToPlay()
		}
		
		if mediaItems.count == 1 {
			UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
		} else {
			UIImpactFeedbackGenerator(style: .heavy).impactOccurredTwice()
		}
	}
	
	final func playLast(_ mediaItems: [MPMediaItem]) {
		if Enabling.inAppPlayer {
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
		
		// As of iOS 14.7 developer beta 1, you must do this in case the user force quit the built-in Music app recently.
		if playbackState != .playing {
			prepareToPlay()
		}
		
		if mediaItems.count == 1 {
			UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
		} else {
			UIImpactFeedbackGenerator(style: .heavy).impactOccurredTwice()
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
