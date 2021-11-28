//
//  TabBarC.swift
//  LavaRock
//
//  Created by h on 2021-10-22.
//

import UIKit
import MediaPlayer

final class TabBarC: UITabBarController {
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		setUpPlaybackStateReflecting()
	}
	
	deinit {
		endObservingPlaybackStateChanges()
	}
	
}

extension TabBarC: PlaybackStateReflecting {
	
	func playbackStateDidChange() {
		guard
			let nc = viewControllers?.last as? UINavigationController,
			nc.viewControllers.first is PlayerVC,
			let tabBarItem = nc.tabBarItem
		else { return }
		if sharedPlayer?.playbackState == .playing {
			tabBarItem.image = .waveSpeakerSymbol
		} else {
			tabBarItem.image = .noWaveSpeakerSymbol
		}
	}
	
}
