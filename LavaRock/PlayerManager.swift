//
//  PlayerManager.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer
import CoreData

final class PlayerManager { // This is a class and not a struct because it should end observing notifications in a deinitializer.
	
	private init() { }
	
	// MARK: - NON-PRIVATE
	
	// MARK: - Properties
	
	// Variables
	private(set) static var player: MPMusicPlayerController?
	private(set) static var songInPlayer: Song? // This could be a computed variable, but every time we compute it, we need the managed object context to fetch, and I'm paranoid about that taking too long.
	
	// MARK: - Setup
	
	static func setUpIfAuthorized() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		player = .systemMusicPlayer
		beginGeneratingNotifications()
		refreshSongInPlayer()
	}
	
	// MARK: - "Now Playing" Indicator
	
	static func nowPlayingIndicator(isInPlayer: Bool) -> (UIImage?, String?) {
		guard
			isInPlayer,
			let player = player
		else {
			return (nil, nil)
		}
		
		if player.playbackState == .playing { // There are many playback states; only show the "playing" icon when the player controller is playing. Otherwise, show the "not playing" icon.
			if #available(iOS 14.0, *) {
				return
					(UIImage(systemName: "speaker.wave.2.fill"),
					 LocalizedString.nowPlaying)
			} else { // iOS 13
				return
					(UIImage(systemName: "speaker.2.fill"),
					 LocalizedString.nowPlaying)
			}
		} else {
			return
				(UIImage(systemName: "speaker.fill"),
				 LocalizedString.paused)
		}
	}
	
	// MARK: - Other
	
	static func refreshSongInPlayer() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let nowPlayingItem = player?.nowPlayingItem
		else {
			songInPlayer = nil
			return
		}
		
		let currentPersistentID = nowPlayingItem.persistentID // Remember: This is a UInt64, and we store the persistentID attribute on each Song as an Int64.
		let songsFetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
		songsFetchRequest.predicate = NSPredicate(format: "persistentID == %lld", Int64(bitPattern: currentPersistentID))
		let songsInPlayer = managedObjectContext.objectsFetched(for: songsFetchRequest)
		
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
	
	// MARK: - Properties
	
	// Constants
	private static let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	// MARK: - Teardown
	
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
