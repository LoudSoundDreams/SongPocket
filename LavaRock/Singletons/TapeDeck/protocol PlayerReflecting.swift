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
	// Adopting types must …
	// • Call `beginReflectingPlaybackState` as soon as their implementation of `reflectPlaybackState` will work.
	
	// Reflect `player`, and show a disabled state if it’s `nil`. (Call `TapeDeck.shared.setUp` to set it up.)
	func reflectPlaybackState()
}
extension PlayerReflecting {
	var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	func beginReflectingPlaybackState() {
		reflectPlaybackState()
		
		TapeDeck.shared.addReflectorOnce(weaklyReferencing: self)
	}
}

