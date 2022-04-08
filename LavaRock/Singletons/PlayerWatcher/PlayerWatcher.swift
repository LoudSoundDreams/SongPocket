//
//  Player.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer
import CoreData

@MainActor
final class PlayerStatusBoard: ObservableObject {
	struct Status {
		let isInPlayMode: Bool
		let isPlayingFirstSongInQueue: Bool
	}
	
	static let shared = PlayerStatusBoard()
	private init() {
		freshen()
	}
	
	@Published private(set) var currentStatus: Status? = nil
	
	final func freshen() {
		guard
			let player = PlayerWatcher.shared.player,
			!(Enabling.playerScreen && SongQueue.contents.isEmpty)
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
final class PlayerWatcher { // This is a class and not a struct because it needs a deinitializer.
	static let shared = PlayerWatcher()
	private init() {}
	
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
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(nowPlayingItemDidChange),
			name: .MPMusicPlayerControllerNowPlayingItemDidChange,
			object: player)
		
		broadcastPlaybackStateDidChange() // Because before anyone called `setUp`, `player` was `nil`, and `MPMediaLibrary.authorizationStatus` might not have been `authorized`.
	}
	@objc
	private func nowPlayingItemDidChange() {
		PlayerStatusBoard.shared.freshen()
	}
	
	@objc
	private func broadcastPlaybackStateDidChange() {
//		print("")
//		print("playback state changed.")
//		print(player.debugDescription)
		
		PlayerStatusBoard.shared.freshen()
		
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
