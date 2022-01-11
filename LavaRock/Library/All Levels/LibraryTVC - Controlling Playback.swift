//
//  LibraryTVC - Controlling Playback.swift
//  LavaRock
//
//  Created by h on 2020-09-15.
//

import UIKit

extension LibraryTVC {
	final func refreshPlaybackButtons() {
		let playButtonAdditionalAccessibilityTraits: UIAccessibilityTraits = .startsMediaSession
		
		func configurePlayButton() {
			playPauseButton.title = LocalizedString.play
			playPauseButton.primaryAction = UIAction(
//				image: UIImage(systemName: "play.circle")
				image: UIImage(systemName: "play.circle.fill")
			) { _ in self.play() }
			// As of iOS 15.3 developer beta 1, even when you set `UIBarButtonItem.width` manually, the "pause.fill" button is still narrower than the "play.fill" button.
			playPauseButton.accessibilityTraits.formUnion(playButtonAdditionalAccessibilityTraits)
		}
		
		func configurePauseButton() {
			playPauseButton.title = LocalizedString.pause
			playPauseButton.primaryAction = UIAction(
//				image: UIImage(systemName: "pause.circle")
				image: UIImage(systemName: "pause.circle.fill")
			) { _ in self.pause() }
			playPauseButton.accessibilityTraits.subtract(playButtonAdditionalAccessibilityTraits)
		}
		
		guard let player = sharedPlayer else {
			configurePlayButton()
			playbackButtons.forEach { $0.disableWithAccessibilityTrait() }
			return
		}
		
		if player.playbackState == .playing {
			configurePauseButton()
		} else {
			configurePlayButton()
		}
		
		// Enable or disable each button as appropriate
		playbackButtons.forEach { $0.enableWithAccessibilityTrait() }
		if player.indexOfNowPlayingItem == 0 {
			previousSongButton.disableWithAccessibilityTrait()
		}
	}
	
	final override func accessibilityPerformMagicTap() -> Bool {
		guard sharedPlayer != nil else {
			return false
		}
		togglePlayPause()
		return true
	}
	
	private func togglePlayPause() {
		guard let player = sharedPlayer else { return }
		if player.playbackState == .playing {
			pause()
		} else {
			play()
		}
	}
	
	final func goToPreviousSong() {
		sharedPlayer?.skipToPreviousItem()
	}
	
	final func rewind() {
		sharedPlayer?.currentPlaybackTime = 0 // As of iOS 15.3 developer beta 1, neither this, `.skipToBeginning`, `.skipToPreviousItem`, nor `.skipToNextItem` reliably changes `.currentPlaybackTime` to `0`.
	}
	
	final func skipBackward() {
		sharedPlayer?.currentPlaybackTime -= 5
	}
	
	private func play() {
		sharedPlayer?.play()
	}
	
	private func pause() {
		sharedPlayer?.pause()
	}
	
	final func skipForward() {
		sharedPlayer?.currentPlaybackTime += 5
	}
	
	final func goToNextSong() {
		sharedPlayer?.skipToNextItem()
	}
}
