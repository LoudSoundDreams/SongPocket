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
		
		func disable(_ barButtonItem: UIBarButtonItem) {
			barButtonItem.isEnabled = false
			barButtonItem.accessibilityTraits.formUnion(.notEnabled)
		}
		
		func enable(_ barButtonItem: UIBarButtonItem) {
			barButtonItem.isEnabled = true
			barButtonItem.accessibilityTraits.subtract(.notEnabled)
		}
		
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let playerController = playerController
		else {
			setPlayPauseButtonToPlayButton()
			for barButtonItem in playbackToolbarButtons {
				disable(barButtonItem)
			}
			return
		}
		
		if playerController.playbackState == .playing { // There are many playback states; only show the pause button when the player controller is playing. Otherwise, show the play button.
			setPlayPauseButtonToPauseButton()
		} else {
			setPlayPauseButtonToPlayButton()
		}
		
		for barButtonItem in playbackToolbarButtons {
			enable(barButtonItem)
		}
		if playerController.indexOfNowPlayingItem == 0 {
			disable(goToPreviousSongButton)
		}
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
