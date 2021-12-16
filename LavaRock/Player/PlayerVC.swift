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
	
	@IBOutlet private  var previousSongButton: UIButton!
	private lazy var previousImage = UIImage(
		systemName: "backward.end.fill",
		withConfiguration: UIImage.SymbolConfiguration.initWithPointSize48())
	
	@IBOutlet private var rewindButton: UIButton!
	private lazy var rewindImage = UIImage(
		systemName: "arrow.counterclockwise.circle.fill",
		withConfiguration: UIImage.SymbolConfiguration.initWithPointSize48())
	
	@IBOutlet private var playPauseButton: UIButton!
	private lazy var playImage = UIImage(
		systemName: "play.fill",
		withConfiguration: UIImage.SymbolConfiguration.initWithPointSize96())
	private lazy var pauseImage = UIImage(
		systemName: "pause.fill",
		withConfiguration: UIImage.SymbolConfiguration.initWithPointSize96())
	
	@IBOutlet private var nextSongButton: UIButton!
	private lazy var nextImage = UIImage(
		systemName: "forward.end.fill",
		withConfiguration: UIImage.SymbolConfiguration.initWithPointSize48())
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		let previousAction = UIAction { _ in self.goToPreviousSong() }
		previousSongButton.addAction(previousAction, for: .touchUpInside)
		previousSongButton.setImage(previousImage, for: .normal)
		
		let rewindAction = UIAction { _ in self.rewind() }
		rewindButton.addAction(rewindAction, for: .touchUpInside)
		rewindButton.setImage(rewindImage, for: .normal)
		
		let togglePlayPauseAction = UIAction { _ in self.togglePlayPause() }
		playPauseButton.addAction(togglePlayPauseAction, for: .touchUpInside)
		
		let nextAction = UIAction { _ in self.goToNextSong() }
		nextSongButton.addAction(nextAction, for: .touchUpInside)
		nextSongButton.setImage(nextImage, for: .normal)
		
		setUpPlaybackStateReflecting()
	}
	
	deinit {
		endObservingPlaybackStateChanges()
	}
	
	private func goToPreviousSong() {
		sharedPlayer?.skipToPreviousItem()
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
	
	private func goToNextSong() {
		sharedPlayer?.skipToNextItem()
	}
	
	@IBAction private func clearRecents(_ sender: UIBarButtonItem) {
		
		
	}
	
	@IBAction private func openMusic(_ sender: UIBarButtonItem) {
		URL.music?.open()
	}
	
}

extension PlayerVC: PlaybackStateReflecting {
	
	func playbackStateDidChange() {
		if sharedPlayer?.playbackState == .playing {
			playPauseButton.setImage(pauseImage, for: .normal)
		} else {
			playPauseButton.setImage(playImage, for: .normal)
		}
		
		if
			sharedPlayer != nil
//			let player = sharedPlayer,
//			player.indexOfNowPlayingItem != 0
		{
			previousSongButton.isEnabled = true
		} else {
			previousSongButton.isEnabled = false
		}
		rewindButton.isEnabled = sharedPlayer != nil
		playPauseButton.isEnabled = sharedPlayer != nil
		nextSongButton.isEnabled = sharedPlayer != nil
	}
	
}
