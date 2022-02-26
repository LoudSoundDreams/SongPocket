//
//  protocol PlaybackStateReflecting.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

import MediaPlayer

@objc
@MainActor
protocol PlaybackStateReflecting: AnyObject {
	// Conforming types must …
	// - Call `beginReflectingPlaybackState` before they need to reflect playback state.
	// - Call `endReflectingPlaybackState` within their deinitializer.
	
	func reflectPlaybackState()
	// Reflect `SharedPlayer.player`, and show a disabled state if it’s `nil`. (Call `SharedPlayer.setUp` to set up `SharedPlayer.player`.)
}

extension PlaybackStateReflecting {
	var player: MPMusicPlayerController? { SharedPlayer.player }
	
	func beginReflectingPlaybackState() {
		reflectPlaybackState()
		
		endReflectingPlaybackState()
		
		SharedPlayer.addReflector(self)
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(reflectPlaybackState),
				name: .MPMusicPlayerControllerPlaybackStateDidChange,
				object: nil)
		}
	}
	
	func endReflectingPlaybackState() {
		SharedPlayer.removeReflector(self)
		NotificationCenter.default.removeObserver(
			self,
			name: .MPMusicPlayerControllerPlaybackStateDidChange,
			object: nil)
	}
}

