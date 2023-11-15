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
		
		reflect_playback_mode_everywhere() // Because before anyone called `beginWatching`, `player` was `nil`, and `MPMediaLibrary.authorizationStatus` might not have been `.authorized`.
		reflect_now_playing_item_everywhere()
		
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(reflect_playback_mode_everywhere),
			name: .MPMusicPlayerControllerPlaybackStateDidChange, // As of iOS 15.4, Media Player also posts this when the repeat or shuffle mode changes.
			object: nil)
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(reflect_now_playing_item_everywhere),
			name: .MPMusicPlayerControllerNowPlayingItemDidChange,
			object: nil)
	}
	
	// MARK: - Private
	
	@objc
	private func reflect_playback_mode_everywhere() {
		TapeDeckStatus.shared.freshen()
		
		reflectors.removeAll { $0.referencee == nil }
		reflectors.forEach {
			$0.referencee?.reflect_playback_mode()
		}
	}
	
	@objc
	private func reflect_now_playing_item_everywhere() {
		TapeDeckStatus.shared.freshen()
		
		reflectors.removeAll { $0.referencee == nil }
		reflectors.forEach {
			$0.referencee?.reflect_now_playing_item()
		}
	}
	
	private var reflectors: [Weak<TapeDeckReflecting>] = []
}
