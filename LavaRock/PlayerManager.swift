//
//  PlayerManager.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer
import CoreData

protocol PlayerManagerObserving: AnyObject {
	func playerManagerDidSetUp()
}

final class PlayerManager { // This is a class and not a struct because it should end observing notifications in a deinitializer.
	
	private init() {}
	
	private static var observers = [PlayerManagerObserving]()
	
	static func addObserver(_ observer: PlayerManagerObserving) {
		observers.append(observer)
	}
	
	static func removeObserver(_ observer: PlayerManagerObserving) {
		if let indexOfMatchingObserver = observers.firstIndex(where: { $0 === observer }) {
			observers.remove(at: indexOfMatchingObserver)
		}
	}
	
	private(set) static var player: MPMusicPlayerController?
	private(set) static var songInPlayer: Song? // This could be a computed variable, but every time we compute it, we need the managed object context to fetch, and I'm paranoid about that taking too long.
	
	static func setUp() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		player = .systemMusicPlayer
		beginGeneratingNotifications()
		refreshSongInPlayer()
		
//		NotificationCenter.default.post(
//			Notification(name: .LRPlayerManagerDidSetUp)
//		)
		
		observers.forEach { $0.playerManagerDidSetUp() }
	}
	
	static func refreshSongInPlayer() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let nowPlayingItem = player?.nowPlayingItem
		else {
			songInPlayer = nil
			return
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
			songInPlayer = nil
			return
		}
		songInPlayer = song
	}
	
	// MARK: - PRIVATE
	
	private static let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	deinit {
		Self.endGeneratingNotifications()
	}
	
	private static func beginGeneratingNotifications() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		player?.beginGeneratingPlaybackNotifications()
	}
	
	private static func endGeneratingNotifications() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		player?.endGeneratingPlaybackNotifications()
	}
	
}
