//
//  Notifications - QueueTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit
import MediaPlayer

extension QueueTVC {
	
	// MARK: - Setup and Teardown
	
	func beginObservingAndGeneratingNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: .LRDidReceiveAuthorizationForAppleMusic,
			object: nil)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: UIApplication.didBecomeActiveNotification,
			object: nil)
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
			object: nil)
		playerController?.beginGeneratingPlaybackNotifications()
		
		// Experimental
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMusicPlayerControllerQueueDidChange,
			object: nil)
	}
	
	func endObservingAndGeneratingNotifications() {
		NotificationCenter.default.removeObserver(self)
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		playerController?.endGeneratingPlaybackNotifications()
	}
	
	// MARK: - Responding
	
	@objc private func didObserve(_ notification: Notification) {
		switch notification.name {
		case .LRDidReceiveAuthorizationForAppleMusic:
			didReceiveAuthorizationForAppleMusic()
		case
			UIApplication.didBecomeActiveNotification,
			.MPMusicPlayerControllerPlaybackStateDidChange,
			.MPMusicPlayerControllerNowPlayingItemDidChange
		:
			print(notification)
			refreshButtons()
		default:
			print("A QueueTVC observed the notification: \(notification.name)")
			print("… but is not set to do anything after observing that notification.")
		}
	}
	
	func didReceiveAuthorizationForAppleMusic() {
		viewDidLoad()
	}
	
}
