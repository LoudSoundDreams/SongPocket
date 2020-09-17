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
	
	func setRefreshedPlaybackToolbar() {
		var playbackButtons: [UIBarButtonItem] = [
			goToPreviousSongButton,
			flexibleSpaceBarButtonItem,
			restartCurrentSongButton,
			flexibleSpaceBarButtonItem,
			playButton,
			flexibleSpaceBarButtonItem,
			goToNextSongButton
		]
		if
			let playerController = playerController,
			playerController.playbackState == .playing // There are many playback states; only show the pause button when the player controller is playing. Otherwise, show the play button.
		{
			if let indexOfPlayButton = playbackButtons.firstIndex(where: { playbackButton in
				playbackButton == playButton
			}) {
				playbackButtons[indexOfPlayButton] = pauseButton
			}
		}
		let shouldAnimateSettingToolbarItems = !refreshesAfterDidSaveChangesFromAppleMusic // This is true if we just got access to the Apple Music library.
		setToolbarItems(playbackButtons, animated: shouldAnimateSettingToolbarItems)
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			goToPreviousSongButton.isEnabled = false
			restartCurrentSongButton.isEnabled = false
			playButton.isEnabled = false
			goToNextSongButton.isEnabled = false
			return
		}
		
		goToPreviousSongButton.isEnabled =
			playerController?.indexOfNowPlayingItem ?? 0 > 0
		restartCurrentSongButton.isEnabled = true
		playButton.isEnabled = true
		pauseButton.isEnabled = true
		goToNextSongButton.isEnabled = true
	}
	
	// MARK: - Controlling Playback
	
	@objc func goToPreviousSong() {
		playerController?.skipToPreviousItem()
	}
	
	@objc func restartCurrentSong() {
		playerController?.skipToBeginning()
	}
	
	@objc func play() {
//		playerController?.prepareToPlay()
		playerController?.play()
	}
	
	@objc func pause() {
		playerController?.pause()
	}
	
	@objc func goToNextSong() {
		playerController?.skipToNextItem()
	}
	
}
