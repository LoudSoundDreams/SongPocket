//
//  PlaybackToolbarManager - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-15.
//

import UIKit
import MediaPlayer

extension LibraryTVC {
	
	// MARK: - Events
	
	final func refreshPlaybackToolbarButtons() {
		
		func setPlayPauseButtonToPlayButton() {
			playPauseButton.image = playButtonImage
			playPauseButton.action = playButtonAction
			playPauseButton.accessibilityLabel = playButtonAccessibilityLabel
			playPauseButton.accessibilityTraits.formUnion(playButtonAdditionalAccessibilityTraits)
		}
		
		func setPlayPauseButtonToPauseButton() {
			playPauseButton.image = pauseButtonImage
			playPauseButton.action = pauseButtonAction
			playPauseButton.accessibilityLabel = pauseButtonAccessibilityLabel
			playPauseButton.accessibilityTraits.subtract(playButtonAdditionalAccessibilityTraits)
		}
		
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let playerController = playerController
		else {
			setPlayPauseButtonToPlayButton()
			for barButtonItem in playbackToolbarButtons {
				barButtonItem.disableIncludingAccessibilityTrait()
			}
			return
		}
		
		if playerController.playbackState == .playing { // There are many playback states; only show the pause button when the player controller is playing. Otherwise, show the play button.
			setPlayPauseButtonToPauseButton()
		} else {
			setPlayPauseButtonToPlayButton()
		}
		
		// Enable or disable each button as appropriate
		
		if playerController.indexOfNowPlayingItem == 0 {
			goToPreviousSongButton.disableIncludingAccessibilityTrait()
		} else {
			goToPreviousSongButton.enableIncludingAccessibilityTrait()
		}
		
//		let currentPlaybackTime = playerController.currentPlaybackTime
//		print(currentPlaybackTime)
//		print(currentPlaybackTime == 0)
//		print("")
//		if
//			playerController.currentPlaybackTime == 0, // As of iOS 14.4 beta 1, doesn't work reliably
//			playerController.playbackState != .playing
//		{
//			disable(restartCurrentSongButton)
//		} else {
			restartCurrentSongButton.enableIncludingAccessibilityTrait()
//		}
		
		playPauseButton.enableIncludingAccessibilityTrait()
		
		goToNextSongButton.enableIncludingAccessibilityTrait()
	}
	
	// MARK: - Controlling Playback
	
	override func accessibilityPerformMagicTap() -> Bool {
		guard playerController != nil else {
			return false
		}
		
		togglePlayPause()
		return true
	}
	
	private func togglePlayPause() {
		guard let playerController = playerController else { return }
		
		if playerController.playbackState == .playing {
			playerController.pause()
		} else {
			playerController.play()
		}
	}
	
	@objc final func goToPreviousSong() {
		playerController?.skipToPreviousItem()
	}
	
	@objc final func restartCurrentSong() {
		playerController?.skipToBeginning()
		playerController?.prepareToPlay() // As of iOS 14.2 beta 3, without this, skipToBeginning() doesn't move the playhead to the beginning (even though it will the next time you tap Play).
		
//		refreshBarButtons() // Disable the "restart current song" button if appropriate, but as of iOS 14.4 beta 1, that doesn't work reliably.
	}
	
	@objc final func play() {
		playerController?.play()
	}
	
	@objc final func pause() {
		playerController?.pause()
	}
	
	@objc final func goToNextSong() {
		playerController?.skipToNextItem()
	}
	
}
