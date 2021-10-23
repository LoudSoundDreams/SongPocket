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
	
	private var sharedPlayer: MPMusicPlayerController? { PlayerManager.player }
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		beginObservingNotifications()
		
		let togglePlayPauseAction = UIAction { _ in self.togglePlayPause() }
		playPauseButton.addAction(togglePlayPauseAction, for: .touchUpInside)
		
		reflectPlaybackState()
	}
	
	private func beginObservingNotifications() {
		NotificationCenter.default.removeObserver(self)
		
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
	}
	private lazy var playImage: UIImage? = {
		UIImage(systemName: "play.fill", withConfiguration: giantSymbolConfiguration)
	}()
	private lazy var pauseImage: UIImage? = {
		UIImage(systemName: "pause.fill", withConfiguration: giantSymbolConfiguration)
	}()
	private let giantSymbolConfiguration = UIImage.SymbolConfiguration.init(pointSize: 288)
	
	private func togglePlayPause() {
		if sharedPlayer?.playbackState == .playing {
			sharedPlayer?.pause()
		} else {
			sharedPlayer?.play()
		}
	}
	
	@IBAction func openMusic(_ sender: UIBarButtonItem) {
		URL.music?.open()
	}
	
	@IBAction func clearRecents(_ sender: UIBarButtonItem) {
		
		
	}
	
}
