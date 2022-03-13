//
//  protocol PlayerReflecting.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

import MediaPlayer

@objc // “generic class 'Weak' requires that 'PlayerReflecting' be a class type”
@MainActor
protocol PlayerReflecting: AnyObject {
	// Conforming types must …
	// - Call `reflectPlaybackStateFromNowOn` as soon as their implementation of `reflectPlaybackState` will work.
	
	func reflectPlaybackState()
	// Reflect `player`, and show a disabled state if it’s `nil`. (Call `Player.shared.setUp` to set it up.)
}

extension PlayerReflecting {
	var player: MPMusicPlayerController? { Player.shared.player }
	
	func reflectPlaybackStateFromNowOn() {
		reflectPlaybackState()
		
		Player.shared.addReflectorOnce(weaklyReferencing: self)
	}
}

