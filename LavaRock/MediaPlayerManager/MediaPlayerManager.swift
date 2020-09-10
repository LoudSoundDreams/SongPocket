//
//  MediaPlayerManager.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer
import CoreData

final class MediaPlayerManager {
	
	// MARK: - Properties
	
	// "Constants"
	static var playerController: MPMusicPlayerController!//?
	private var library: MPMediaLibrary?
	
	// Variables
	var shouldNextMergeBeSynchronous = false
	
	// MARK: - Setup and Teardown
	
	func setUpLibraryIfAuthorized() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return
		}
		
		Self.playerController = MPMusicPlayerApplicationController.systemMusicPlayer
		library = MPMediaLibrary.default()
		mergeChangesFromAppleMusic()
		beginObservingAndGeneratingNotifications()
	}
	
	deinit {
		endObservingAndGeneratingNotifications()
	}
	
	// MARK: - Notifications
	
	func beginObservingAndGeneratingNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: UIApplication.didBecomeActiveNotification,
			object: nil)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMediaLibraryDidChange,
			object: nil)
		library?.beginGeneratingLibraryChangeNotifications()
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange, // Doesn't work?
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
			object: nil)
		Self.playerController.beginGeneratingPlaybackNotifications() // Doesn't work?
		
		// Experimental
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMusicPlayerControllerQueueDidChange,
			object: nil)
	}
	
	// After observing notifications, funnel control flow through here, rather than calling methods directly, to make debugging easier.
	@objc func didObserve(_ notification: Notification) {
		switch notification.name {
		case
			UIApplication.didBecomeActiveNotification, // Update toolbar buttons, current song
			.MPMusicPlayerControllerPlaybackStateDidChange, // Update toolbar buttons
			.MPMusicPlayerControllerNowPlayingItemDidChange // Update current song. if it's not in the list, don't highlight any song
		:
			break //
		case .MPMediaLibraryDidChange:
			mergeChangesFromAppleMusic()
		default:
			print("An instance of \(Self.self) observed the notification: \(notification.name)")
			print("… but the app is not set to do anything after observing that notification.")
		}
	}
	
	func endObservingAndGeneratingNotifications() {
		NotificationCenter.default.removeObserver(self)
		library?.endGeneratingLibraryChangeNotifications()
		Self.playerController.endGeneratingPlaybackNotifications()
	}
	
}
