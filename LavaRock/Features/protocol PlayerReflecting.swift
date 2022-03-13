//
//  protocol PlayerReflecting.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

import MediaPlayer

@objc
@MainActor
protocol PlayerReflecting: AnyObject {
	// Conforming types must …
	// - Call `beginReflectingPlaybackState` as soon as their implementation of `reflectPlaybackState` will work.
	
	func reflectPlaybackState()
	// Reflect `player`, and show a disabled state if it’s `nil`. (Call `Player.shared.setUp` to set it up.)
}

extension PlayerReflecting {
	var player: MPMusicPlayerController? { Player.shared.player }
	
	func beginReflectingPlaybackState() {
		reflectPlaybackState()
		
		Player.shared.addReflectorOnce(weaklyReferencing: self)
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(reflectPlaybackState),
				name: .MPMusicPlayerControllerPlaybackStateDidChange,
				object: player)
		}
	}
}

