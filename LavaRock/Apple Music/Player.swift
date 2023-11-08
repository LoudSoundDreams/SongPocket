//
//  Player.swift
//  LavaRock
//
//  Created by h on 2022-03-19.
//

import MusicKit
import MediaPlayer

@MainActor
extension SystemMusicPlayer {
	static var sharedIfAuthorized: SystemMusicPlayer? {
		guard MusicAuthorization.currentStatus == .authorized else {
			return nil
		}
		return .shared
	}
}

extension MPMusicPlayerController {
	static var systemMusicPlayerIfAuthorized: MPMusicPlayerController? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		return .systemMusicPlayer
	}
}
@MainActor
extension MPMusicPlayerController {
	final func playNow(
		_ mediaItems: [MPMediaItem],
		numberToSkip: Int
	) {
		setQueue(with: MPMediaItemCollection(items: mediaItems))
		
		play()
		repeatMode = .none
		shuffleMode = .off
		if numberToSkip >= 1 {
			for _ in 1...numberToSkip {
				// As of iOS 16.5 developer beta 4, you must do this after calling `play`, not before, or it won’t actually work.
				skipToNextItem()
			}
		}
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
