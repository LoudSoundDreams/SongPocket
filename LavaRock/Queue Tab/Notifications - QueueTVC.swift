//
//  Notifications - QueueTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit

extension QueueTVC {
	
	// MARK: - Setup and Teardown
	
	func beginObservingAndGeneratingNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: UIApplication.didBecomeActiveNotification,
			object: nil)
		
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
		playerController.beginGeneratingPlaybackNotifications()
		
		// Experimental
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMusicPlayerControllerQueueDidChange,
			object: nil)
	}
	
	func endObservingNotifications() {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Responding
	
	@objc private func didObserve(_ notification: Notification) {
		switch notification.name {
		case
			UIApplication.didBecomeActiveNotification,
			.MPMusicPlayerControllerPlaybackStateDidChange,
			.MPMusicPlayerControllerNowPlayingItemDidChange
		:
			refreshButtons()
		default:
			print("A QueueTVC observed the notification: \(notification.name)")
			print("… but is not set to do anything after observing that notification.")
		}
	}
	
}
