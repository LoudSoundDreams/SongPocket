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
	// - Call `setUpPlaybackStateReflecting` before they need to reflect playback state.
	// - Call `endObservingPlaybackStateChanges` within their deinitializer.
	func playbackStateDidChange()
}

extension PlaybackStateReflecting {
	
	var sharedPlayer: MPMusicPlayerController? { PlayerManager.player }
	
	func setUpPlaybackStateReflecting() {
		playbackStateDidChange()
		
		endObservingPlaybackStateChanges()
		
		PlayerManager.addObserver(self)
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(playbackStateDidChange),
				name: .MPMusicPlayerControllerPlaybackStateDidChange,
				object: nil)
		}
	}
	
	// `PlayerManager.player` is `nil` until `PlayerManager` sets it up.
	func playerManagerDidSetUp() {
		setUpPlaybackStateReflecting()
	}
	
	func endObservingPlaybackStateChanges() {
		PlayerManager.removeObserver(self)
		NotificationCenter.default.removeObserver(
			self,
			name: .MPMusicPlayerControllerPlaybackStateDidChange,
			object: nil)
	}
	
}

final class PlayerManager { // This is a class and not a struct because it should end observing notifications in a deinitializer.
	
	private init() {}
	
	private static var observers: [PlaybackStateReflecting] = []
	static func addObserver(_ observer: PlaybackStateReflecting) {
		observers.append(observer)
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
		
		observers.forEach { $0.playerManagerDidSetUp() }
	}
	
	static func songInPlayer(context: NSManagedObjectContext) -> Song? {
		guard let nowPlayingItem = player?.nowPlayingItem else {
			return nil
		}
		
		let currentPersistentID_asInt64 = Int64(bitPattern: nowPlayingItem.persistentID)
		let songsFetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
		songsFetchRequest.predicate = NSPredicate(
			format: "persistentID == %lld",
			currentPersistentID_asInt64)
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
