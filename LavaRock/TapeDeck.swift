// 2020-11-04

@objc // “generic class 'Weak' requires that 'TapeDeckReflecting' be a class type”
@MainActor protocol TapeDeckReflecting: AnyObject {
	// Adopting types must…
	// • Set `TapeDeck.shared.reflectorToolbar` as soon as their implementations of `reflect_playbackState` and `reflect_nowPlaying` will work.
	
	func reflect_playbackState()
	// Reflect `TapeDeck.shared.player`, and show a disabled state if it’s `nil`. (Call `TapeDeck.shared.watchMPPlayer` to set it up.)
	
	func reflect_nowPlaying()
}

import MediaPlayer
@MainActor final class TapeDeck {
	private init() {}
	static let shared = TapeDeck()
	
	var reflectorToolbar: Weak<MainToolbar>? = nil
	
	func watchMPPlayer() {
		guard let __player = MPMusicPlayerController._system else { return }
		
		__player.beginGeneratingPlaybackNotifications()
		
		playbackState() // Because before anyone called `watchMPPlayer`, `player` was `nil`, and `MPMediaLibrary.authorizationStatus` might not have been `.authorized`.
		nowPlaying()
		
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(playbackState),
			name: .MPMusicPlayerControllerPlaybackStateDidChange, // As of iOS 15.4, Media Player also posts this when the repeat or shuffle mode changes.
			object: nil)
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(nowPlaying),
			name: .MPMusicPlayerControllerNowPlayingItemDidChange,
			object: nil)
	}
	@objc private func playbackState() {
		reflectorToolbar?.referencee?.reflect_playbackState()
	}
	@objc private func nowPlaying() {
		reflectorToolbar?.referencee?.reflect_nowPlaying()
	}
}
