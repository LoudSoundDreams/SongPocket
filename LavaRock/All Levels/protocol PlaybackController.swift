//
//  protocol PlaybackController.swift
//  LavaRock
//
//  Created by h on 2020-09-15.
//

import UIKit

protocol PlaybackController {
	var playbackButtons: [UIBarButtonItem] { get set }
	
	var previousSongButton: UIBarButtonItem { get set }
	var rewindButton: UIBarButtonItem { get set }
	var playPauseButton: UIBarButtonItem { get set }
	var nextSongButton: UIBarButtonItem { get set }
	
	func refreshPlaybackButtons()
}
