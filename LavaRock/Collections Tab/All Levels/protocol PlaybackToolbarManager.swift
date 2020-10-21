//
//  protocol PlaybackToolbarManager.swift
//  LavaRock
//
//  Created by h on 2020-09-15.
//

import UIKit
import MediaPlayer

protocol PlaybackToolbarManager {
	var playbackToolbarButtons: [UIBarButtonItem] { get set }
	var goToPreviousSongButton: UIBarButtonItem { get set }
	var restartCurrentSongButton: UIBarButtonItem { get set }
	var playButtonImage: UIImage? { get }
	var playButtonAction: Selector { get }
	var playButtonAccessibilityLabel: String { get }
	var playButtonAdditionalAccessibilityTraits: UIAccessibilityTraits { get }
	var pauseButtonImage: UIImage? { get }
	var pauseButtonAction: Selector { get }
	var pauseButtonAccessibilityLabel: String { get }
	var playPauseButton: UIBarButtonItem { get set }
	var goToNextSongButton: UIBarButtonItem { get set }
	
	func didReceiveAuthorizationForAppleMusic()
	func refreshPlaybackToolbarButtons()
	
	func goToPreviousSong()
	func restartCurrentSong()
	func play()
	func pause()
	func goToNextSong()
}
