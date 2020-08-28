//
//  MediaPlayerManager.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer
import CoreData

extension Notification.Name {
	static let LRDidMergeChangesFromAppleMusicLibrary = Notification.Name("MediaPlayerManager has merged changes from the Apple Music library into the Core Data store. Objects that depend on either of those should observe this notification, and respond appropriately at this point.")
}

class MediaPlayerManager {
	
	// MARK: Properties
	
	// "Constants"
	static var playerController: MPMusicPlayerController!//? = nil
	private var library: MPMediaLibrary? = nil
	lazy var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	// MARK: Methods
	
	deinit {
		endObservingAndGeneratingNotifications()
	}
	
	func setUpLibraryIfAuthorized() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return
		}
		
		Self.playerController = MPMusicPlayerApplicationController.systemMusicPlayer
		library = MPMediaLibrary.default()
		mergeChangesFromAppleMusicLibrary()
		beginObservingAndGeneratingNotifications()
	}
	
	func beginObservingAndGeneratingNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: UIApplication.didBecomeActiveNotification, // Works
			object: nil)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMediaLibraryDidChange, // Works
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
		print("Observed notification: \(notification.name)")
		switch notification.name {
		case
			UIApplication.didBecomeActiveNotification, // Update toolbar buttons, current song
			.MPMusicPlayerControllerPlaybackStateDidChange, // Update toolbar buttons
			.MPMusicPlayerControllerNowPlayingItemDidChange // Update current song. if it's not in the list, don't highlight any song
		:
			break
//			updateIndexOfHighlightedItemDueToNotification()
//			refreshUI()
		case .MPMediaLibraryDidChange: // Update toolbar buttons, curr
			DispatchQueue.global(qos: .userInitiated).async {
				print("We should merge changes from the Apple Music library at this point.")
//				self.mergeChangesFromAppleMusicLibrary() // TO DO: MERGE ON A NEW MANAGED OBJECT CONTEXT, BECAUSE THIS HAPPENS ON A DIFFERENT THREAD.
				DispatchQueue.main.async { // Notifications are dealt with on the thread you post them in, so post this notification on the main thread.
					NotificationCenter.default.post(
						Notification(name: Notification.Name.LRDidMergeChangesFromAppleMusicLibrary)
					)
				}
			}
			
//			reloadSongs()
//			refreshUI()
		
		
		default:
			print("… but the app is not set to do anything after observing that notification.")
		}
	}
	
	func endObservingAndGeneratingNotifications() {
		NotificationCenter.default.removeObserver(self)
		library?.endGeneratingLibraryChangeNotifications()
		Self.playerController.endGeneratingPlaybackNotifications()
	}
	
}
