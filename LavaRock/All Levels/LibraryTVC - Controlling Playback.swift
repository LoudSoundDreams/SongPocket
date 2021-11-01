//
//  LibraryTVC - Controlling Playback.swift
//  LavaRock
//
//  Created by h on 2020-09-15.
//

import UIKit
import MediaPlayer

extension LibraryTVC {
	
	final func refreshPlaybackButtons() {
		let playButtonAdditionalAccessibilityTraits: UIAccessibilityTraits = .startsMediaSession
		
		func configurePlayButton() {
			playPauseButton.primaryAction = UIAction(
				image: UIImage(systemName: "play.fill")
			) { _ in self.play() }
//			playPauseButton.width = 10.0 // As of iOS 14.7.1, even when you set the width of each button manually, the "pause.fill" button is still narrower than the "play.fill" button.
			playPauseButton.accessibilityLabel = LocalizedString.play
			playPauseButton.accessibilityTraits.formUnion(playButtonAdditionalAccessibilityTraits)
		}
		
		func configurePauseButton() {
			playPauseButton.primaryAction = UIAction(
				image: UIImage(systemName: "pause.fill")
			) { _ in self.pause() }
//			playPauseButton.width = 10.0
			playPauseButton.accessibilityLabel = LocalizedString.pause
			playPauseButton.accessibilityTraits.subtract(playButtonAdditionalAccessibilityTraits)
		}
		
		guard let player = sharedPlayer else {
			configurePlayButton()
			playbackButtons.forEach { $0.disableWithAccessibilityTrait() }
			return
		}
		
		if player.playbackState == .playing { // There are many playback states; only show the pause button when the player controller is playing. Otherwise, show the play button.
			configurePauseButton()
		} else {
			configurePlayButton()
		}
		
		// Enable or disable each button as appropriate
		
		if player.indexOfNowPlayingItem == 0 {
			previousSongButton.disableWithAccessibilityTrait()
		} else {
			previousSongButton.enableWithAccessibilityTrait()
		}
		
//		let currentPlaybackTime = sharedPlayer.currentPlaybackTime
//		print(currentPlaybackTime)
//		print(currentPlaybackTime == 0)
//		print("")
//		if
//			sharedPlayer.currentPlaybackTime == 0,
//			sharedPlayer.playbackState != .playing
//		{
//			rewindButton.disableWithAccessibilityTrait()
//		} else {
			rewindButton.enableWithAccessibilityTrait()
//		}
		
		playPauseButton.enableWithAccessibilityTrait()
		
		nextSongButton.enableWithAccessibilityTrait()
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
//		sharedPlayer?.currentPlaybackTime = 0 // Changing the "now playing" item triggers refreshPlaybackButtons(), but as of iOS 14.4 developer beta 1, without this line of code, we can actually finish all that before currentPlaybackTime actually changes to 0 for the new song, which causes us to not disable the "restart current song" button when we should.
		// Actually, that line of code makes this method take forever to return; it repeatedly prints "SYNC-WATCHDOG-1: Attempting to wake up the remote process" and "SYNC-WATCHDOG-2: Tearing down connection". That happens whether we set currentPlaybackTime = 0 before or after changing the song.
		
		sharedPlayer?.skipToPreviousItem()
	}
	
	final func rewind() {
		sharedPlayer?.currentPlaybackTime = 0 // As of iOS 14.4 developer beta 1, skipToBeginning() doesn't reliably change currentPlaybackTime to 0, which causes us to not disable the "restart current song" when we should; but this line of code does.
//		sharedPlayer?.skipToBeginning()
//		sharedPlayer?.prepareToPlay()
		
//		refreshPlaybackButtons() // Disable the "restart current song" button if appropriate.
	}
	
	private func play() {
		sharedPlayer?.play()
	}
	
	private func pause() {
		sharedPlayer?.pause()
	}
	
	final func goToNextSong() {
//		sharedPlayer?.currentPlaybackTime = 0 // See corresponding comment in goToPreviousSong().
		
		sharedPlayer?.skipToNextItem()
	}
	
}
