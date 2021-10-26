//
//  PlayerVC.swift
//  LavaRock
//
//  Created by h on 2021-10-19.
//

import UIKit
import MediaPlayer

final class PlayerVC: UIViewController {
	
	// Controls
	@IBOutlet private var rewindButton: UIButton!
	private let rewindImage = UIImage(
			systemName: "arrow.counterclockwise.circle.fill",
			withConfiguration: UIImage.SymbolConfiguration.init(pointSize: 48))
	@IBOutlet private var playPauseButton: UIButton!
	private lazy var playImage = UIImage(
		systemName: "play.fill",
		withConfiguration: playPauseSymbolConfiguration)
	private lazy var pauseImage = UIImage(
		systemName: "pause.fill",
		withConfiguration: playPauseSymbolConfiguration)
	private let playPauseSymbolConfiguration = UIImage.SymbolConfiguration.init(pointSize: 96)
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		let rewindAction = UIAction { _ in self.rewind() }
		rewindButton.addAction(rewindAction, for: .touchUpInside)
		rewindButton.setImage(rewindImage, for: .normal)
		
		let togglePlayPauseAction = UIAction { _ in self.togglePlayPause() }
		playPauseButton.addAction(togglePlayPauseAction, for: .touchUpInside)
		
		setUpPlaybackStateReflecting()
	}
	
	deinit {
		endObservingPlaybackStateChanges()
	}
	
	private func rewind() {
		sharedPlayer?.currentPlaybackTime = 0
	}
	
	private func togglePlayPause() {
		if sharedPlayer?.playbackState == .playing {
			sharedPlayer?.pause()
		} else {
			sharedPlayer?.play()
		}
	}
	
	@IBAction private func clearRecents(_ sender: UIBarButtonItem) {
		
		
	}
	
	@IBAction private func openMusic(_ sender: UIBarButtonItem) {
		URL.music?.open()
	}
	
}

extension PlayerVC: PlaybackStateReflecting {
	
	func reflectPlaybackState() {
		if sharedPlayer?.playbackState == .playing {
			playPauseButton.setImage(pauseImage, for: .normal)
		} else {
			playPauseButton.setImage(playImage, for: .normal)
		}
		
		rewindButton.isEnabled = sharedPlayer != nil
		playPauseButton.isEnabled = sharedPlayer != nil
	}
	
}
