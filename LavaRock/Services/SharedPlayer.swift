//
//  SharedPlayer.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer
import CoreData

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

@MainActor
final class SharedPlayer { // This is a class and not a struct because it should end observing notifications in a deinitializer.
	private init() {}
	
	static func addReflector(_ reflector: PlaybackStateReflecting) {
		let weakReflector = Weak(reflector)
		reflectors.append(weakReflector)
	}
	static func removeReflector(_ reflector: PlaybackStateReflecting) {
		if let indexOfMatchingReflector = reflectors.firstIndex(where: { reflector === $0 }) {
			reflectors.remove(at: indexOfMatchingReflector)
		}
	}
	
	private(set) static var player: MPMusicPlayerController? = nil
	
	static func setUp() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		player?.endGeneratingPlaybackNotifications()
		if Enabling.queue {
			player = .applicationQueuePlayer
		} else {
			player = .systemMusicPlayer
		}
		player?.beginGeneratingPlaybackNotifications()
		
		reflectors.removeAll { $0.referencee == nil }
		reflectors.forEach {
			// Because before anyone called this method, `player` was `nil`.
			$0.referencee?.beginReflectingPlaybackState()
		}
	}
	
	static func songInPlayer(context: NSManagedObjectContext) -> Song? {
		guard let nowPlayingItem = player?.nowPlayingItem else {
			return nil
		}
		
		let currentSongFileID = SongFileID(bitPattern: nowPlayingItem.persistentID)
		let songsFetchRequest = Song.fetchRequest()
		songsFetchRequest.predicate = NSPredicate(
			format: "persistentID == %lld",
			currentSongFileID)
		let songsInPlayer = context.objectsFetched(for: songsFetchRequest)
		
		guard
			songsInPlayer.count == 1,
			let song = songsInPlayer.first
		else {
			return nil
		}
		return song
	}
	
	// MARK: - Private
	
	private static var reflectors: [Weak<PlaybackStateReflecting>] = []
	
	deinit {
		DispatchQueue.main.sync {
			Self.player?.endGeneratingPlaybackNotifications()
		}
	}
}
