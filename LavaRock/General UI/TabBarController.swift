//
//  TabBarController.swift
//  LavaRock
//
//  Created by h on 2021-10-22.
//

import UIKit

final class TabBarController: UITabBarController {
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		beginReflectingPlaybackState()
	}
	
	deinit {
		endReflectingPlaybackState()
	}
}

extension TabBarController: PlaybackStateReflecting {
	func reflectPlaybackState() {
//		guard
//			let nc = viewControllers?.last as? UINavigationController,
//			nc.viewControllers.first is PlayerVC,
//			let tabBarItem = nc.tabBarItem
//		else { return }
//		if player?.playbackState == .playing {
//			tabBarItem.image = UIImage(systemName: .SFSpeakerWave)
//		} else {
//			tabBarItem.image = UIImage(systemName: .SFSpeakerNoWave)
//		}
	}
}
