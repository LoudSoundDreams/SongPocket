//
//  protocol PlaybackToolbarManager.swift
//  LavaRock
//
//  Created by h on 2020-09-15.
//

import UIKit

protocol PlaybackToolbarManager {
	var playbackToolbarButtons: [UIBarButtonItem] { get set }
	
	var goToPreviousSongButton: UIBarButtonItem { get set }
	var rewindButton: UIBarButtonItem { get set }
	var playImage: UIImage? { get }
	var playAction: Selector { get }
	var playAccessibilityLabel: String { get }
	var playButtonAdditionalAccessibilityTraits: UIAccessibilityTraits { get }
	var pauseImage: UIImage? { get }
	var pauseAction: Selector { get }
	var pauseAccessibilityLabel: String { get }
	var playPauseButton: UIBarButtonItem { get set }
	var goToNextSongButton: UIBarButtonItem { get set }
	
	func refreshPlaybackToolbarButtons()
	
	func goToPreviousSong()
	func rewind()
	func play()
	func pause()
	func goToNextSong()
}
