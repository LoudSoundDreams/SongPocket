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
	static let shared = TapeDeck()
	private init() {}
	
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
		if Enabling.console {
			player = .applicationQueuePlayer
		} else {
			player = .systemMusicPlayer
		}
		player?.beginGeneratingPlaybackNotifications()
		
		reflect_playback_mode_everywhere() // Because before anyone called `setUp`, `player` was `nil`, and `MPMediaLibrary.authorizationStatus` might not have been `authorized`.
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
	
	@objc
	private func reflect_playback_mode_everywhere() {
		TapeDeckDisplay.shared.freshenStatus()
		
		reflectors.removeAll { $0.referencee == nil }
		reflectors.forEach {
			$0.referencee?.reflect_playback_mode()
		}
	}
	
	@objc
	private func reflect_now_playing_item_everywhere() {
		TapeDeckDisplay.shared.freshenStatus()
		
		reflectors.removeAll { $0.referencee == nil }
		reflectors.forEach {
			$0.referencee?.reflect_now_playing_item()
		}
	}
	
	func songContainingPlayhead(via context: NSManagedObjectContext) -> Song? {
#if targetEnvironment(simulator)
		guard let songID = Global.songID else {
			return nil
		}
		let songIDToMatch = songID
#else
		guard let nowPlayingItem = player?.nowPlayingItem else {
			return nil
		}
		let songIDToMatch = SongID(bitPattern: nowPlayingItem.persistentID)
#endif
		
		let songsContainingPlayhead = context.objectsFetched(for: { () -> NSFetchRequest<Song> in
			let request = Song.fetchRequest()
			request.predicate = NSPredicate(
				format: "persistentID == %lld",
				songIDToMatch)
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
	
	private var reflectors: [Weak<TapeDeckReflecting>] = []
	
	deinit {
		Task {
			await player?.endGeneratingPlaybackNotifications()
		}
	}
}
