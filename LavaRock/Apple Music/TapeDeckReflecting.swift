//
//  TapeDeckReflecting.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

import Foundation

@objc // “generic class 'Weak' requires that 'TapeDeckReflecting' be a class type”
@MainActor
protocol TapeDeckReflecting: AnyObject {
	// Adopting types must…
	// • Call `TapeDeck.shared.addReflector(weakly: self)` as soon as their implementations of `reflect_playbackState` and `reflect_nowPlaying` will work.
	
	func reflect_playbackState()
	// Reflect `TapeDeck.shared.player`, and show a disabled state if it’s `nil`. (Call `TapeDeck.shared.beginWatching` to set it up.)
	
	func reflect_nowPlaying()
}
