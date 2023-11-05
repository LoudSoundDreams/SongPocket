//
//  Player.swift
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
		return Sim_Global.currentSong?.songInfo()?.songID
#else
		guard let nowPlayingItem else {
			return nil
		}
		return SongID(bitPattern: nowPlayingItem.persistentID)
#endif
	}
	
	final func playNow(
		_ mediaItems: [MPMediaItem],
		numberToSkip: Int
	) {
		let interval = Self.signposter.beginInterval("set queue and play")
		defer {
			Self.signposter.endInterval("set queue and play", interval)
		}
		
		setQueue(with: MPMediaItemCollection(items: mediaItems))
		
		let playInterval = Self.signposter.beginInterval("play")
		play()
		repeatMode = .none
		shuffleMode = .off
		if numberToSkip >= 1 {
			for _ in 1...numberToSkip {
				// As of iOS 16.5 developer beta 4, you must do this after calling `play`, not before, or it won’t actually work.
				skipToNextItem()
			}
		}
		Self.signposter.endInterval("play", playInterval)
	}
	
	final func playLast(_ mediaItems: [MPMediaItem]) {
		// As of iOS 15.4, when using `MPMusicPlayerController.systemMusicPlayer` and the queue is empty, this does nothing, but I can’t find a workaround.
		append(
			MPMusicPlayerMediaItemQueueDescriptor(
				itemCollection: MPMediaItemCollection(items: mediaItems)
			)
		)
		
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
}
