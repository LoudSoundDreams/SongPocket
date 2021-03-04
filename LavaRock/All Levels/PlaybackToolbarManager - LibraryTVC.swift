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
			let playerController = sharedPlayerController
		else {
			setPlayPauseButtonToPlayButton()
			for barButtonItem in playbackToolbarButtons {
				barButtonItem.disableWithAccessibilityTrait()
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
			goToPreviousSongButton.disableWithAccessibilityTrait()
		} else {
			goToPreviousSongButton.enableWithAccessibilityTrait()
		}
		
//		let currentPlaybackTime = sharedPlayerController.currentPlaybackTime
//		print(currentPlaybackTime)
//		print(currentPlaybackTime == 0)
//		print("")
//		if
//			sharedPlayerController.currentPlaybackTime == 0,
//			sharedPlayerController.playbackState != .playing
//		{
//			restartCurrentSongButton.disableWithAccessibilityTrait()
//		} else {
			restartCurrentSongButton.enableWithAccessibilityTrait()
//		}
		
		playPauseButton.enableWithAccessibilityTrait()
		
		goToNextSongButton.enableWithAccessibilityTrait()
	}
	
	// MARK: - Controlling Playback
	
	final override func accessibilityPerformMagicTap() -> Bool {
		guard sharedPlayerController != nil else {
			return false
		}
		
		togglePlayPause()
		return true
	}
	
	private func togglePlayPause() {
		guard let playerController = sharedPlayerController else { return }
		
		if playerController.playbackState == .playing {
			playerController.pause()
		} else {
			playerController.play()
		}
	}
	
	@objc final func goToPreviousSong() {
//		sharedPlayerController?.currentPlaybackTime = 0 // Changing the now-playing item triggers refreshPlaybackToolbarButtons(), but as of iOS 14.4 beta 1, without this line of code, we can actually finish all that before currentPlaybackTime actually changes to 0 for the new song, which causes us to not disable the "restart current song" button when we should.
		// Actually, that line of code makes this method take forever to return; it repeatedly prints "SYNC-WATCHDOG-1: Attempting to wake up the remote process" and "SYNC-WATCHDOG-2: Tearing down connection". That happens whether we set currentPlaybackTime = 0 before or after changing the song.
		
		sharedPlayerController?.skipToPreviousItem()
	}
	
	@objc final func restartCurrentSong() {
		sharedPlayerController?.currentPlaybackTime = 0 // As of iOS 14.4 beta 1, skipToBeginning() doesn't reliably change currentPlaybackTime to 0, which causes us to not disable the "restart current song" when we should; but this line of code does.
//		sharedPlayerController?.skipToBeginning()
//		sharedPlayerController?.prepareToPlay()
		
		refreshBarButtons() // Disable the "restart current song" button if appropriate.
	}
	
	@objc final func play() {
		sharedPlayerController?.play()
	}
	
	@objc final func pause() {
		sharedPlayerController?.pause()
	}
	
	@objc final func goToNextSong() {
//		sharedPlayerController?.currentPlaybackTime = 0 // See comment in goToPreviousSong().
		
		sharedPlayerController?.skipToNextItem()
	}
	
}
