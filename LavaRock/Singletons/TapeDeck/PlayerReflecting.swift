//
//  PlayerReflecting.swift
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
	
	func reflectPlaybackState()
	// Reflect `TapeDeck.shared.player`, and show a disabled state if it’s `nil`. (Call `TapeDeck.shared.setUp` to set it up.)
}
extension PlayerReflecting {
	func beginReflectingPlaybackState() {
		reflectPlaybackState()
		
		TapeDeck.shared.addReflectorOnce(weaklyReferencing: self)
	}
}

