//
//  PlayerManager.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer
import CoreData

final class PlayerManager { // This is a class and not a struct because it should end observing notifications in a deinitializer.
	
	private init() {}
	
	private(set) static var player: MPMusicPlayerController?
	private(set) static var songInPlayer: Song? // This could be a computed variable, but every time we compute it, we need the managed object context to fetch, and I'm paranoid about that taking too long.
	
	static func setUp() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		player = .systemMusicPlayer
		beginGeneratingNotifications()
		refreshSongInPlayer()
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
