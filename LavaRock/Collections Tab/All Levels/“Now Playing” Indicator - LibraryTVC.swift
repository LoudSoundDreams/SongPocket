//
//  “Now Playing” Indicator - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-11-19.
//

import UIKit

extension LibraryTVC {
	
	// LibraryTVC itself doesn't call this, but its subclasses might want to.
	final func nowPlayingIndicator(isNowPlayingItem: Bool) -> (UIImage?, String?) {
		if
			isNowPlayingItem,
			let playerController = playerController
		{
			if playerController.playbackState == .playing { // There are many playback states; only show the "playing" icon when the player controller is playing. Otherwise, show the "not playing" icon.
				if #available(iOS 14.0, *) {
					return (
						UIImage(systemName: "speaker.wave.2.fill"),
						"Now playing")
				} else { // iOS 13
					return (
						UIImage(systemName: "speaker.2.fill"),
						"Now playing")
				}
			} else {
				return (
					UIImage(systemName: "speaker.fill"),
					"Paused")
			}
		} else {
			return (nil, nil)
		}
	}
	
}
