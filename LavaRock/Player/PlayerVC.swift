//
//  PlayerVC.swift
//  LavaRock
//
//  Created by h on 2021-10-19.
//

import UIKit

final class PlayerVC: UIViewController {
	// `PlaybackToolbarManaging`
	private(set) lazy var previousSongButton = makePreviousSongButton()
	private(set) lazy var rewindButton = makeRewindButton()
	private(set) lazy var skipBackwardButton = makeSkipBackwardButton()
	private(set) lazy var playPauseButton = UIBarButtonItem()
	private(set) lazy var skipForwardButton = makeSkipForwardButton()
	private(set) lazy var nextSongButton = makeNextSongButton()
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		beginReflectingPlaybackState()
		
		toolbarItems = playbackToolbarButtons
	}
	
	deinit {
		endReflectingPlaybackState()
	}
}

extension PlayerVC: PlaybackStateReflecting {
	func reflectPlaybackState() {
		freshenPlaybackToolbar()
	}
}

extension PlayerVC: PlaybackToolbarManaging {}
