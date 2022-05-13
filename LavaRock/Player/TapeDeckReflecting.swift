//
//  TapeDeckReflecting.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

import MediaPlayer

@objc // “generic class 'Weak' requires that 'TapeDeckReflecting' be a class type”
@MainActor
protocol TapeDeckReflecting: AnyObject {
	// Adopting types must …
	// • Call `TapeDeck.shared.addReflector(weakly: self)` as soon as their implementations of `reflectPlaybackState` and `reflectNowPlayingItem` will work.
	
	func reflectPlaybackState()
	// Reflect `TapeDeck.shared.player`, and show a disabled state if it’s `nil`. (Call `TapeDeck.shared.setUp` to set it up.)
	
	func reflectNowPlayingItem()
}
