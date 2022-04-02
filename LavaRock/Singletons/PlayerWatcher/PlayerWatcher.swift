//
//  Player.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer
import CoreData

@MainActor
final class PlayerWatcher { // This is a class and not a struct because it needs a deinitializer.
	private init() {}
	static let shared = PlayerWatcher()
	
	final func addReflectorOnce(weaklyReferencing newReflector: PlayerReflecting) {
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
		if Enabling.playerScreen {
			player = .applicationQueuePlayer
		} else {
			player = .systemMusicPlayer
		}
		player?.beginGeneratingPlaybackNotifications()
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(broadcastPlaybackStateDidChange),
			name: .MPMusicPlayerControllerPlaybackStateDidChange, // As of iOS 15.4, Media Player also posts this when the repeat or shuffle mode changes.
			object: player)
		
		broadcastPlaybackStateDidChange() // Because before anyone called `setUp`, `player` was `nil`, and `MPMediaLibrary.authorizationStatus` might not have been `authorized`.
	}
	
	@objc
	private func broadcastPlaybackStateDidChange() {
//		print("")
//		print("playback state changed.")
//		print(player.debugDescription)
		
		reflectors.removeAll { $0.referencee == nil }
		reflectors.forEach {
			$0.referencee?.playbackStateDidChange()
		}
	}
	
	final func songInPlayer(context: NSManagedObjectContext) -> Song? {
		guard let nowPlayingItem = player?.nowPlayingItem else {
			return nil
		}
		
		let songsInPlayer = context.objectsFetched(for: { () -> NSFetchRequest<Song> in
			let request = Song.fetchRequest()
			request.predicate = NSPredicate(
				format: "persistentID == %lld",
				MPSongID(bitPattern: nowPlayingItem.persistentID))
			return request
		}())
		guard
			songsInPlayer.count == 1,
			let song = songsInPlayer.first
		else {
			return nil
		}
		return song
	}
	
	// MARK: - Private
	
	private var reflectors: [Weak<PlayerReflecting>] = []
	
	deinit {
		player?.endGeneratingPlaybackNotifications()
	}
}