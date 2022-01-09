//
//  PlayerManager.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer
import CoreData

@objc protocol PlaybackStateReflecting: AnyObject {
	// Conforming types must …
	// - Call `beginReflectingPlaybackState` before they need to reflect playback state.
	// - Call `endReflectingPlaybackState` within their deinitializer.
	
	// Reflect `PlayerManager.player`, and show a disabled state if it's `nil`. (Call `PlayerManager.setUp` to set up `PlayerManager.player`.)
	func reflectPlaybackState()
}

extension PlaybackStateReflecting {
	var sharedPlayer: MPMusicPlayerController? { PlayerManager.player }
	
	func beginReflectingPlaybackState() {
		reflectPlaybackState()
		
		endReflectingPlaybackState()
		
		PlayerManager.addObserver(self)
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(reflectPlaybackState),
				name: .MPMusicPlayerControllerPlaybackStateDidChange,
				object: nil)
		}
	}
	
	func endReflectingPlaybackState() {
		PlayerManager.removeObserver(self)
		NotificationCenter.default.removeObserver(
			self,
			name: .MPMusicPlayerControllerPlaybackStateDidChange,
			object: nil)
	}
}

final class PlayerManager { // This is a class and not a struct because it should end observing notifications in a deinitializer.
	private init() {}
	
	private final class WeakPlaybackStateReflecting {
		weak var observer: PlaybackStateReflecting? = nil
		init(observer: PlaybackStateReflecting) { self.observer = observer }
	}
	private static var observers: [WeakPlaybackStateReflecting] = []
	static func addObserver(_ observer: PlaybackStateReflecting) {
		let weakObserver = WeakPlaybackStateReflecting(observer: observer)
		observers.append(weakObserver)
	}
	static func removeObserver(_ observer: PlaybackStateReflecting) {
		if let indexOfMatchingObserver = observers.firstIndex(where: { $0 === observer }) {
			observers.remove(at: indexOfMatchingObserver)
		}
	}
	
	private(set) static var player: MPMusicPlayerController? = nil
	
	static func setUp() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		player = .systemMusicPlayer
		player?.beginGeneratingPlaybackNotifications()
		
		observers.removeAll { $0.observer == nil }
		// Because before anyone called this method, `player` was `nil`.
		observers.forEach {
			if let observer = $0.observer {
				observer.beginReflectingPlaybackState()
			}
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
	
	deinit {
		Self.player?.endGeneratingPlaybackNotifications()
	}
}
