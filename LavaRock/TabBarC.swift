//
//  TabBarC.swift
//  LavaRock
//
//  Created by h on 2021-10-22.
//

import UIKit
import MediaPlayer

final class TabBarC: UITabBarController {
	
	private var sharedPlayer: MPMusicPlayerController? { PlayerManager.player }

    override func viewDidLoad() {
        super.viewDidLoad()

        beginObservingNotifications()
		
		reflectPlaybackState()
    }
	
	private func beginObservingNotifications() {
		PlayerManager.removeObserver(self)
		NotificationCenter.default.removeObserver(self)
		
		PlayerManager.addObserver(self)
		
		// `PlayerManager.player` is `nil` until `CollectionsTVC` makes `PlayerManager` set it up.
//		NotificationCenter.default.addObserver(
//			self,
//			selector: #selector(playerManagerDidSetUp),
//			name: Notification.Name.LRPlayerManagerDidSetUp,
//			object: nil)
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(playbackStateMaybeDidChange),
			name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
			object: nil)
	}
	
//	@objc private func playerManagerDidSetUp() {
//		reflectPlaybackState()
//	}
	
	@objc private func playbackStateMaybeDidChange() {
		reflectPlaybackState()
	}
	
	private let notPlayingImage = UIImage(systemName: "speaker.fill")
	private let playingImage = UIImage(systemName: "speaker.wave.2.fill")
	
	private func reflectPlaybackState() {
		guard
			let navigationC = viewControllers?.last as? UINavigationController,
			navigationC.viewControllers.first is PlayerVC,
			let tabBarItem = navigationC.tabBarItem
		else { return }
		if sharedPlayer?.playbackState == .playing {
			tabBarItem.image = playingImage
		} else {
			tabBarItem.image = notPlayingImage
		}
	}
	
}

extension TabBarC: PlayerManagerObserving {
	
	func playerManagerDidSetUp() {
		reflectPlaybackState()
	}
	
}
