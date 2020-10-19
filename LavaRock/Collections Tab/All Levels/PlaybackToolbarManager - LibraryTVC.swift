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
	
	final func setRefreshedPlaybackToolbar(animated: Bool = false) { // Only animate this when entering and exiting editing mode, or immediately after receiving authorization for the user's Apple Music library.
		var playbackButtons = [
			goToPreviousSongButton,
			flexibleSpaceBarButtonItem,
			restartCurrentSongButton,
			flexibleSpaceBarButtonItem,
			playButton,
			flexibleSpaceBarButtonItem,
			goToNextSongButton
		]
		
		func setDisabledPlaybackToolbar() {
			goToPreviousSongButton.isEnabled = false
			restartCurrentSongButton.isEnabled = false
			playButton.isEnabled = false
			goToNextSongButton.isEnabled = false
			setToolbarItems(playbackButtons, animated: true)
		}
		
		if
			MPMediaLibrary.authorizationStatus() != .authorized
//				|| (self is CollectionsTVC && indexedLibraryItems.count == 0) // there are no songs in the Apple Music library
		{
			setDisabledPlaybackToolbar()
			return
		}
		
		if
			let playerController = playerController,
			playerController.playbackState == .playing // There are many playback states; only show the pause button when the player controller is playing. Otherwise, show the play button.
		{
			if let indexOfPlayButton = playbackButtons.firstIndex(of: playButton) {
				playbackButtons[indexOfPlayButton] = pauseButton
			}
		}
		
		goToPreviousSongButton.isEnabled =
			playerController?.indexOfNowPlayingItem ?? 0 > 0
		restartCurrentSongButton.isEnabled = true
		playButton.isEnabled = true
		pauseButton.isEnabled = true
		goToNextSongButton.isEnabled = true
		
		setToolbarItems(playbackButtons, animated: animated)
	}
	
	// MARK: - Controlling Playback
	
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
