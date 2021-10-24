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

    final override func viewDidLoad() {
        super.viewDidLoad()

		setUp()
    }
	
	private func setUp() {
		beginObservingNotifications()
		reflectPlaybackState()
	}
	
	private func beginObservingNotifications() {
		PlayerManager.removeObserver(self)
		PlayerManager.addObserver(self)
		
		NotificationCenter.default.removeObserver(self)
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(playbackStateMaybeDidChange),
				name: .MPMusicPlayerControllerPlaybackStateDidChange,
				object: nil)
		}
	}
	
	@objc private func playbackStateMaybeDidChange() {
		reflectPlaybackState()
	}
	
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
	private let notPlayingImage = UIImage(systemName: "speaker.fill")
	private let playingImage = UIImage(systemName: "speaker.wave.2.fill")
	
}

extension TabBarC: PlayerManagerObserving {
	
	// `PlayerManager.player` is `nil` until `CollectionsTVC` makes `PlayerManager` set it up.
	final func playerManagerDidSetUp() {
		setUp()
	}
	
}
