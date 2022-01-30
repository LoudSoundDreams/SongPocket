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
	func reflectPlaybackState() {
		if sharedPlayer?.playbackState == .playing {
			playPauseButton.setImage(
				UIImage(systemName: .SFPause, withConfiguration: .symbol96),
				for: .normal)
		} else {
			playPauseButton.setImage(
				UIImage(systemName: .SFPlay, withConfiguration: .symbol96),
				for: .normal)
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
