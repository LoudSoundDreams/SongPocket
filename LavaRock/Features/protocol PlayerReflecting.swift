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
	// Reflect `Player.shared.player`, and show a disabled state if it’s `nil`. (Call `Player.shared.setUp` to set up `Player.shared.player`.)
}

extension PlayerReflecting {
	var player: MPMusicPlayerController? { Player.shared.player }
	
	func beginReflectingPlaybackState() {
		reflectPlaybackState()
		
		endReflectingPlaybackState()
		
		Player.shared.addReflector(self)
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(reflectPlaybackState),
				name: .MPMusicPlayerControllerPlaybackStateDidChange,
				object: nil)
		}
	}
	
	func endReflectingPlaybackState() {
		Player.shared.removeReflector(self)
		NotificationCenter.default.removeObserver(
			self,
			name: .MPMusicPlayerControllerPlaybackStateDidChange,
			object: nil)
	}
}

