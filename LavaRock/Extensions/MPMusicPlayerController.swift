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
		return Sim_Global.currentSongID
#else
		guard let nowPlayingItem else {
			return nil
		}
		return SongID(bitPattern: nowPlayingItem.persistentID)
#endif
	}
	
	final func playNow(
		_ mediaItems: [MPMediaItem],
		skipping numberToSkip: Int
	) {
		let interval = Self.signposter.beginInterval("set queue and play")
		defer {
			Self.signposter.endInterval("set queue and play", interval)
		}
		
		setQueue(mediaItems: mediaItems)
		
		// As of iOS 15.6 RC 2, with `systemMusicPlayer`, you must set `repeatMode` and `shuffleMode` after calling `setQueue`, not before, or they won’t actually apply.
		repeatMode = .none
		shuffleMode = .off
		
		let playInterval = Self.signposter.beginInterval("play")
		play()
		if numberToSkip >= 1 {
			for _ in 1...numberToSkip {
				// As of iOS 16.5 developer beta 4, you must do this after calling `play`, not before, or it won’t actually work.
				skipToNextItem()
			}
		}
		Self.signposter.endInterval("play", playInterval)
	}
	
	final func playNext(_ mediaItems: [MPMediaItem]) {
		prepend(mediaItems)
		
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
		// As of iOS 15.4, when using `MPMusicPlayerController.systemMusicPlayer` and the queue is empty, this does nothing, but I can’t find a workaround.
		append(mediaItems)
		
		// As of iOS 14.7 developer beta 1, you must do this in case the user force quit Apple Music recently.
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
