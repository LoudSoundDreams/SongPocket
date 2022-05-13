//
//  TapeDeck.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer
import CoreData

@MainActor
final class TapeDeckDisplay: ObservableObject {
	struct Status {
		let isInPlayMode: Bool
		let isPlayingFirstSongInQueue: Bool
	}
	
	static let shared = TapeDeckDisplay()
	private init() {
		freshen()
	}
	
	@Published private(set) var currentStatus: Status? = nil
	
	final func freshen() {
		guard
			let player = TapeDeck.shared.player,
			!(Enabling.console && Reel.mediaItems.isEmpty)
		else {
			currentStatus = nil
			return
		}
		currentStatus = Status(
			isInPlayMode: player.playbackState == .playing,
			isPlayingFirstSongInQueue: player.indexOfNowPlayingItem == 0)
	}
}

@MainActor
final class TapeDeck { // This is a class and not a struct because it needs a deinitializer.
	static let shared = TapeDeck()
	private init() {}
	
	final func addReflectorOnce(weaklyReferencing newReflector: TapeDeckReflecting) {
		if let indexOfMatchingReflector = reflectors.firstIndex(where: { weakReflector in
			newReflector === weakReflector.referencee
		}) {
			reflectors.remove(at: indexOfMatchingReflector)
		}
		
		reflectors.append(Weak(newReflector))
	}
	
	private(set) var player: MPMusicPlayerController? = nil
	
	final func setUp() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		player?.endGeneratingPlaybackNotifications()
		if Enabling.console {
			player = .applicationQueuePlayer
		} else {
			player = .systemMusicPlayer
		}
		player?.beginGeneratingPlaybackNotifications()
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(reflectPlaybackStateEverywhere),
			name: .MPMusicPlayerControllerPlaybackStateDidChange, // As of iOS 15.4, Media Player also posts this when the repeat or shuffle mode changes.
			object: player)
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(nowPlayingItemDidChange),
			name: .MPMusicPlayerControllerNowPlayingItemDidChange,
			object: player)
		
		reflectPlaybackStateEverywhere() // Because before anyone called `setUp`, `player` was `nil`, and `MPMediaLibrary.authorizationStatus` might not have been `authorized`.
	}
	@objc
	private func nowPlayingItemDidChange() {
		TapeDeckDisplay.shared.freshen()
	}
	
	@objc
	private func reflectPlaybackStateEverywhere() {
//		print("")
//		print("playback state changed.")
//		print(player.debugDescription)
		
		TapeDeckDisplay.shared.freshen()
		
		reflectors.removeAll { $0.referencee == nil }
		reflectors.forEach {
			$0.referencee?.reflectPlaybackState()
		}
	}
	
	final func songContainingPlayhead(via: NSManagedObjectContext) -> Song? {
		guard let nowPlayingItem = player?.nowPlayingItem else {
			return nil
		}
		
		let songsContainingPlayhead = via.objectsFetched(for: { () -> NSFetchRequest<Song> in
			let request = Song.fetchRequest()
			request.predicate = NSPredicate(
				format: "persistentID == %lld",
				SongID(bitPattern: nowPlayingItem.persistentID))
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
		player?.endGeneratingPlaybackNotifications()
	}
}
