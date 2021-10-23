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
	@IBOutlet private var playPauseButton: UIButton!
	@IBOutlet private var rewindButton: UIButton!
	
	private var sharedPlayer: MPMusicPlayerController? { PlayerManager.player }
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		beginObservingNotifications()
		
		let rewindAction = UIAction { _ in self.rewind() }
		rewindButton.addAction(rewindAction, for: .touchUpInside)
		rewindButton.setImage(rewindImage, for: .normal)
		
		let togglePlayPauseAction = UIAction { _ in self.togglePlayPause() }
		playPauseButton.addAction(togglePlayPauseAction, for: .touchUpInside)
		
		reflectPlaybackState()
	}
	private let rewindImage: UIImage? = {
		UIImage(
			systemName: "arrow.counterclockwise.circle.fill",
			withConfiguration: UIImage.SymbolConfiguration.init(pointSize: 48))
	}()
	
	private func beginObservingNotifications() {
		PlayerManager.removeObserver(self)
		NotificationCenter.default.removeObserver(self)
		
		PlayerManager.addObserver(self)
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(playbackStateMaybeDidChange),
			name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
			object: nil)
	}
	
	@objc private func playbackStateMaybeDidChange() {
		reflectPlaybackState()
	}
	
	private func reflectPlaybackState() {
		if sharedPlayer?.playbackState == .playing {
			playPauseButton.setImage(pauseImage, for: .normal)
		} else {
			playPauseButton.setImage(playImage, for: .normal)
		}
		
		rewindButton.isEnabled = sharedPlayer != nil
		playPauseButton.isEnabled = sharedPlayer != nil
	}
	private lazy var playImage: UIImage? = {
		UIImage(systemName: "play.fill", withConfiguration: playPauseSymbolConfiguration)
	}()
	private lazy var pauseImage: UIImage? = {
		UIImage(systemName: "pause.fill", withConfiguration: playPauseSymbolConfiguration)
	}()
	private let playPauseSymbolConfiguration = UIImage.SymbolConfiguration.init(pointSize: 96)
	
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
	
	@IBAction func clearRecents(_ sender: UIBarButtonItem) {
		
		
	}
	
	@IBAction func openMusic(_ sender: UIBarButtonItem) {
		URL.music?.open()
	}
	
}

extension PlayerVC: PlayerManagerObserving {
	
	// `PlayerManager.player` is `nil` until `CollectionsTVC` makes `PlayerManager` set it up.
	func playerManagerDidSetUp() {
		beginObservingNotifications()
		reflectPlaybackState()
	}
	
}
