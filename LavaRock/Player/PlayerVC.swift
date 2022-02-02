//
//  PlayerVC.swift
//  LavaRock
//
//  Created by h on 2021-10-19.
//

import UIKit

final class PlayerVC: UIViewController {
	
	
	@IBOutlet private var previousSongButton: UIButton!
	@IBOutlet private var rewindButton: UIButton!
	@IBOutlet private var playPauseButton: UIButton!
	@IBOutlet private var nextSongButton: UIButton!
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		previousSongButton.removeFromSuperview()
		rewindButton.removeFromSuperview()
		playPauseButton.removeFromSuperview()
		nextSongButton.removeFromSuperview()
		
		
		
		previousSongButton.addAction(UIAction { _ in self.goToPreviousSong() }, for: .touchUpInside)
		previousSongButton.setImage(
			UIImage(systemName: .SFPreviousTrack, withConfiguration: .symbol48),
			for: .normal)
		
		rewindButton.addAction(UIAction { _ in self.rewind() }, for: .touchUpInside)
		rewindButton.setImage(
			UIImage(systemName: .SFRewind, withConfiguration: .symbol48),
			for: .normal)
		
		playPauseButton.addAction(UIAction { _ in self.togglePlayPause() }, for: .touchUpInside)
		
		nextSongButton.addAction(UIAction { _ in self.goToNextSong() }, for: .touchUpInside)
		nextSongButton.setImage(
			UIImage(systemName: .SFNextTrack, withConfiguration: .symbol48),
			for: .normal)
		
		beginReflectingPlaybackState()
	}
	
	deinit {
		endReflectingPlaybackState()
	}
	
	private func goToPreviousSong() {
		player?.skipToPreviousItem()
	}
	
	private func rewind() {
		player?.currentPlaybackTime = 0
	}
	
	private func togglePlayPause() {
		if player?.playbackState == .playing {
			player?.pause()
		} else {
			player?.play()
		}
	}
	
	private func goToNextSong() {
		player?.skipToNextItem()
	}
}

extension PlayerVC: PlaybackStateReflecting {
	func reflectPlaybackState() {
		if player?.playbackState == .playing {
			playPauseButton.setImage(
				UIImage(systemName: .SFPause, withConfiguration: .symbol96),
				for: .normal)
		} else {
			playPauseButton.setImage(
				UIImage(systemName: .SFPlay, withConfiguration: .symbol96),
				for: .normal)
		}
		
		if
			player != nil
//			let player = player,
//			player.indexOfNowPlayingItem != 0
		{
			previousSongButton.isEnabled = true
		} else {
			previousSongButton.isEnabled = false
		}
		rewindButton.isEnabled = player != nil
		playPauseButton.isEnabled = player != nil
		nextSongButton.isEnabled = player != nil
	}
}
