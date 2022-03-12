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
	// - Call `beginReflectingPlaybackState` before they need to reflect playback state.
	// - Call `endReflectingPlaybackState` within their deinitializer.
	
	func reflectPlaybackState()
	// Reflect `player`, and show a disabled state if it’s `nil`. (Call `Player.shared.setUp` to set it up.)
}

extension PlayerReflecting {
	var player: MPMusicPlayerController? { Player.shared.player }
	
	func beginReflectingPlaybackState() {
		reflectPlaybackState()
		
		endReflectingPlaybackState()
		
		Player.shared.addReflector(weaklyReferencing: self)
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(reflectPlaybackState),
				name: .MPMusicPlayerControllerPlaybackStateDidChange,
				object: player)
		}
	}
	
	func endReflectingPlaybackState() {
		NotificationCenter.default.removeObserver(
			self,
			name: .MPMusicPlayerControllerPlaybackStateDidChange,
			object: player)
	}
}

