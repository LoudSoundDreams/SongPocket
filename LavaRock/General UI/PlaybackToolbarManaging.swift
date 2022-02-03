//
//  PlayerControlling.swift
//  LavaRock
//
//  Created by h on 2022-02-02.
//

import UIKit
import MediaPlayer

protocol PlaybackToolbarManaging: PlaybackStateReflecting {
	// Conforming types might want to …
	// - Override `accessibilityPerformMagicTap` and toggle playback.
	var previousSongButton: UIBarButtonItem { get }
	var rewindButton: UIBarButtonItem { get }
	var skipBackwardButton: UIBarButtonItem { get }
	var playPauseButton: UIBarButtonItem { get }
	var skipForwardButton: UIBarButtonItem { get }
	var nextSongButton: UIBarButtonItem { get }
}

extension PlaybackToolbarManaging {
	var playbackToolbarButtons: [UIBarButtonItem] {
		return [
			previousSongButton, .flexibleSpace(),
			rewindButton, .flexibleSpace(),
//			skipBackwardButton, .flexibleSpace(),
			playPauseButton, .flexibleSpace(),
//			skipForwardButton, .flexibleSpace(),
			nextSongButton,
		]
	}
	
	func makePreviousSongButton() -> UIBarButtonItem {
		let button = UIBarButtonItem(
			title: LocalizedString.previousTrack,
			image: UIImage(systemName: .SFPreviousTrack),
			primaryAction: UIAction { _ in
				self.player?.skipToPreviousItem()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}
	
	func makeRewindButton() -> UIBarButtonItem {
		let button = UIBarButtonItem(
			title: LocalizedString.restart,
			image: UIImage(systemName: .SFRewind),
			primaryAction: UIAction { _ in
				self.player?.currentPlaybackTime = 0 // As of iOS 15.3 developer beta 1, neither this, `.skipToBeginning`, `.skipToPreviousItem`, nor `.skipToNextItem` reliably changes `.currentPlaybackTime` to `0`.
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}
	
	func makeSkipBackwardButton() -> UIBarButtonItem {
		let button = UIBarButtonItem(
			title: LocalizedString.skip10SecondsBackwards,
			image: UIImage(systemName: .SFSkipBack10),
			primaryAction: UIAction { _ in
				self.player?.currentPlaybackTime -= 10
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}
	
	func makeSkipForwardButton() -> UIBarButtonItem {
		let button = UIBarButtonItem(
			title: LocalizedString.skip10SecondsForward,
			image: UIImage(systemName: .SFSkipForward10),
			primaryAction: UIAction { _ in
				self.player?.currentPlaybackTime += 10
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}
	
	func makeNextSongButton() -> UIBarButtonItem {
		let button = UIBarButtonItem(
			title: LocalizedString.nextTrack,
			image: UIImage(systemName: .SFNextTrack),
			primaryAction: UIAction { _ in
				self.player?.skipToNextItem()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}
	
	func freshenPlaybackToolbar() {
		func configurePlayButton() {
			playPauseButton.title = LocalizedString.play
			playPauseButton.primaryAction = UIAction(
				image: UIImage(systemName: .SFPlay)
			) { _ in
				self.player?.play()
			}
			// As of iOS 15.3 developer beta 1, even when you set `UIBarButtonItem.width` manually, the “pause.fill” button is still narrower than the “play.fill” button.
			playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
		}
		
		guard let player = player else {
			configurePlayButton()
			playbackToolbarButtons.forEach { $0.disableWithAccessibilityTrait() }
			return
		}
		
		if player.playbackState == .playing {
			playPauseButton.title = LocalizedString.pause
			playPauseButton.primaryAction = UIAction(
				image: UIImage(systemName: .SFPause)
			) { _ in
				self.player?.pause()
			}
			playPauseButton.accessibilityTraits.subtract(.startsMediaSession)
		} else {
			configurePlayButton()
		}
		
		// Enable or disable each button as appropriate
		playbackToolbarButtons.forEach { $0.enableWithAccessibilityTrait() }
		if player.indexOfNowPlayingItem == 0 {
			previousSongButton.disableWithAccessibilityTrait()
		}
	}
}
