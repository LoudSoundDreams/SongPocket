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
	// Adopting types must …
	// • Call `TapeDeck.shared.addReflector(weakly: self)` as soon as their implementations of `reflect_playback_mode` and `reflect_now_playing_item` will work.
	
	func reflect_playback_mode()
	// Reflect `TapeDeck.shared.player`, and show a disabled state if it’s `nil`. (Call `TapeDeck.shared.beginWatching` to set it up.)
	
	func reflect_now_playing_item()
}
