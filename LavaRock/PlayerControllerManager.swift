//
//  PlayerControllerManager.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer
import CoreData

final class PlayerControllerManager {
	
	// MARK: - Properties
	
	// "Constants"
	static let shared = PlayerControllerManager()
	var playerController: MPMusicPlayerController?
	private var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	// Variables
	var currentSong: Song? // This could be a computed variable, but every time we compute it, we need the managed object context to fetch, and I'm paranoid about that taking too long.
	
	// MARK: - Setup and Teardown
	
	private init() { }
	
	func setUpPlayerControllerIfAuthorized() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		playerController = MPMusicPlayerController.systemMusicPlayer
		beginGeneratingNotifications()
		refreshCurrentSong()
	}
	
	deinit {
		endGeneratingNotifications()
	}
	
	// MARK: - Notifications
	
	private func beginGeneratingNotifications() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		playerController?.beginGeneratingPlaybackNotifications()
	}
	
	private func endGeneratingNotifications() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		playerController?.endGeneratingPlaybackNotifications()
	}
	
	// MARK: - Other
	
	func refreshCurrentSong() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let nowPlayingItem = playerController?.nowPlayingItem
		else {
			currentSong = nil
			return
		}
		
		let currentPersistentID = nowPlayingItem.persistentID // Remember: This is a UInt64, and we store the persistentID attribute on each Song as an Int64.
		let songsFetchRequest = NSFetchRequest<Song>(entityName: "Song")
		songsFetchRequest.predicate = NSPredicate(format: "persistentID == %lld", Int64(bitPattern: currentPersistentID))
		let nowPlayingSongs = managedObjectContext.objectsFetched(for: songsFetchRequest)
		
		guard
			nowPlayingSongs.count == 1,
			let nowPlayingSong = nowPlayingSongs.first
		else {
			currentSong = nil
			return
		}
		currentSong = nowPlayingSong
	}
	
}
