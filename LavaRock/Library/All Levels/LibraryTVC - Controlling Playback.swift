//
//  LibraryTVC - Controlling Playback.swift
//  LavaRock
//
//  Created by h on 2020-09-15.
//

import UIKit

extension LibraryTVC {
	final func freshenPlaybackButtons() {
		let playButtonAdditionalAccessibilityTraits: UIAccessibilityTraits = .startsMediaSession
		
		func configurePlayButton() {
			playPauseButton.title = LocalizedString.play
			playPauseButton.primaryAction = UIAction(
				image: UIImage(systemName: .SFPlay)
			) { _ in self.play() }
			// As of iOS 15.3 developer beta 1, even when you set `UIBarButtonItem.width` manually, the “pause.fill” button is still narrower than the “play.fill” button.
			playPauseButton.accessibilityTraits.formUnion(playButtonAdditionalAccessibilityTraits)
		}
		
		guard let player = player else {
			configurePlayButton()
			playbackButtons.forEach { $0.disableWithAccessibilityTrait() }
			return
		}
		
		if player.playbackState == .playing {
			playPauseButton.title = LocalizedString.pause
			playPauseButton.primaryAction = UIAction(
				image: UIImage(systemName: .SFPause)
			) { _ in self.pause() }
			playPauseButton.accessibilityTraits.subtract(playButtonAdditionalAccessibilityTraits)
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
		guard let player = player else {
			return false
		}
		if player.playbackState == .playing {
			pause()
		} else {
			play()
		}
		return true
	}
	
	private func play() {
		player?.play()
	}
	
	private func pause() {
		player?.pause()
	}
}
