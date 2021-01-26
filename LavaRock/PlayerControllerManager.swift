//
//  PlayerControllerManager.swift
//  LavaRock
//
//  Created by h on 2020-11-04.
//

import MediaPlayer
import CoreData

final class PlayerControllerManager { // This is a class and not a struct because it should end observing notifications in a deinitializer.
	
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
	
	// MARK: - "Now Playing" Indicator
	
	final func nowPlayingIndicator(isItemNowPlaying: Bool) -> (UIImage?, String?) {
		guard
			isItemNowPlaying,
			let playerController = playerController
		else {
			return (nil, nil)
		}
		
		if playerController.playbackState == .playing { // There are many playback states; only show the "playing" icon when the player controller is playing. Otherwise, show the "not playing" icon.
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
	
	func refreshCurrentSong() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let nowPlayingItem = playerController?.nowPlayingItem
		else {
			currentSong = nil
			return
		}
		
		let currentPersistentID = nowPlayingItem.persistentID // Remember: This is a UInt64, and we store the persistentID attribute on each Song as an Int64.
		let songsFetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
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
