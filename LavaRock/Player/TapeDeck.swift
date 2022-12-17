//
//  TapeDeck.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer
import CoreData

@MainActor
final class TapeDeck { // This is a class and not a struct because it needs a deinitializer.
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
	
	private(set) var player: MPMusicPlayerController? = nil // TO DO: Prints noise to the console when running in the Simulator
	
	func setUp() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		player?.endGeneratingPlaybackNotifications()
		if Enabling.inAppPlayer {
			player = .applicationQueuePlayer
		} else {
			player = .systemMusicPlayer
		}
		player?.beginGeneratingPlaybackNotifications()
		
		reflect_playback_mode_everywhere() // Because before anyone called `setUp`, `player` was `nil`, and `MPMediaLibrary.authorizationStatus` might not have been `.authorized`.
		reflect_now_playing_item_everywhere()
		
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(reflect_playback_mode_everywhere),
			name: .MPMusicPlayerControllerPlaybackStateDidChange, // As of iOS 15.4, Media Player also posts this when the repeat or shuffle mode changes.
			object: player)
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(reflect_now_playing_item_everywhere),
			name: .MPMusicPlayerControllerNowPlayingItemDidChange,
			object: player)
	}
	
	func songContainingPlayhead(via context: NSManagedObjectContext) -> Song? {
		guard let songID_to_match = player?.now_playing_SongID() else {
			return nil
		}
		
		let songsContainingPlayhead = context.objectsFetched(for: { () -> NSFetchRequest<Song> in
			let request = Song.fetchRequest()
			request.predicate = NSPredicate(
				format: "persistentID == %lld",
				songID_to_match)
			return request
		}())
		guard
			songsContainingPlayhead.count == 1,
			let song = songsContainingPlayhead.first
		else {
			return nil
		}
		return song
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
	
	deinit {
		player?.endGeneratingPlaybackNotifications()
	}
}
