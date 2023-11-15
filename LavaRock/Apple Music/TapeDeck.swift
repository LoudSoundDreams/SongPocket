//
//  TapeDeck.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer

@MainActor
final class TapeDeck {
	private init() {}
	static let shared = TapeDeck()
	
	private var reflectors: [Weak<TapeDeckReflecting>] = []
	func addReflector(weakly newReflector: TapeDeckReflecting) {
		if let indexOfMatchingReflector = reflectors.firstIndex(where: { weakReflector in
			newReflector === weakReflector.referencee
		}) {
			reflectors.remove(at: indexOfMatchingReflector)
		}
		
		reflectors.append(Weak(newReflector))
	}
	
	func beginWatching() {
		guard let player = MPMusicPlayerController.systemMusicPlayerIfAuthorized else { return }
		
		player.beginGeneratingPlaybackNotifications()
		
		playbackState() // Because before anyone called `beginWatching`, `player` was `nil`, and `MPMediaLibrary.authorizationStatus` might not have been `.authorized`.
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
		reflectors.removeAll { $0.referencee == nil }
		reflectors.forEach {
			$0.referencee?.reflect_playbackState()
		}
	}
	@objc private func nowPlaying() {
		reflectors.removeAll { $0.referencee == nil }
		reflectors.forEach {
			$0.referencee?.reflect_nowPlaying()
		}
	}
}
