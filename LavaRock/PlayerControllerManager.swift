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
//	var currentSong: Song? {
//		currentSongFetched()
//	}
	var currentSong: Song? // This could be a computed variable, but every time we compute it, we need the managed object context to fetch, and I'm paranoid about that taking too long.
	
	// MARK: - Setup and Teardown
	
	private init() { }
	
	func setUpPlayerControllerIfAuthorized() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		playerController = MPMusicPlayerController.systemMusicPlayer
		beginObservingAndGeneratingNotifications()
		refreshCurrentSong()
	}
	
	deinit {
		endObservingAndGeneratingNotifications()
	}
	
	
//	private func currentSongFetched() -> Song? {
//		guard
//			MPMediaLibrary.authorizationStatus() == .authorized,
//			let nowPlayingItem = playerController?.nowPlayingItem
//		else {
//			return nil
//		}
//
//		let currentPersistentID = nowPlayingItem.persistentID // Remember: This is a UInt64, and we store the persistentID attribute on each Song as an Int64.
//		let songsFetchRequest = NSFetchRequest<Song>(entityName: "Song")
//		songsFetchRequest.predicate = NSPredicate(format: "persistentID == %lld", Int64(bitPattern: currentPersistentID))
//		let nowPlayingSongs = managedObjectContext.objectsFetched(for: songsFetchRequest)
//
//		guard
//			nowPlayingSongs.count == 1,
//			let nowPlayingSong = nowPlayingSongs.first
//		else {
//			return nil
//		}
//		return nowPlayingSong
//	}
	
	
	// MARK: - Notifications
	
	// MARK: Setup and Teardown
	
	private func beginObservingAndGeneratingNotifications() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
//		NotificationCenter.default.addObserver(
//			self,
//			selector: #selector(didObserve(_:)),
//			name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
//			object: nil)
		playerController?.beginGeneratingPlaybackNotifications()
	}
	
	private func endObservingAndGeneratingNotifications() {
//		NotificationCenter.default.removeObserver(self)
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		playerController?.endGeneratingPlaybackNotifications()
	}
	
	// MARK: Responding
	
//	@objc private func didObserve(_ notification: Notification) {
//		switch notification.name {
//		case
//			UIApplication.didBecomeActiveNotification,
//			.MPMusicPlayerControllerNowPlayingItemDidChange
//		:
//			refreshCurrentSong()
//		default:
//			print("\(Self.self) observed the notification: \(notification.name)")
//			print("… but is not set to do anything after observing that notification.")
//		}
//	}
	
	/*private */func refreshCurrentSong() {
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
