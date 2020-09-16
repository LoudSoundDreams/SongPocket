//
//  protocol PlaybackToolbarManager.swift
//  LavaRock
//
//  Created by h on 2020-09-15.
//

import UIKit
import MediaPlayer

protocol PlaybackToolbarManager {
	var goToPreviousSongButton: UIBarButtonItem { get set }
	var restartCurrentSongButton: UIBarButtonItem { get set }
	var goToNextSongButton: UIBarButtonItem { get set }
	var playButton: UIBarButtonItem { get set }
	var pauseButton: UIBarButtonItem { get set }
	
	func didReceiveAuthorizationForAppleMusic()
	func setAndRefreshPlaybackToolbar()
	
	func goToPreviousSong()
	func restartCurrentSong()
	func play()
	func pause()
	func goToNextSong()
}
