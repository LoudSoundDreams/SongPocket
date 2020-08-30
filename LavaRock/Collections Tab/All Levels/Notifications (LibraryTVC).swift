//
//  Notifications (LibraryTVC).swift
//  LavaRock
//
//  Created by h on 2020-08-29.
//

import UIKit
import MediaPlayer

extension LibraryTVC {
	
	// MARK: - Setup and Teardown
	
	func startObservingNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.LRDidMergeChangesFromAppleMusicLibrary,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.LRDidChangeAccentColor,
			object: nil)
	}
	
	func endObservingNotifications() {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Responding
	
	@objc func didObserve(_ notification: Notification) {
		print("Observed notification: \(notification.name)")
		switch notification.name {
		case .LRDidMergeChangesFromAppleMusicLibrary:
			didMergeFromAppleMusicLibrary(notification)
		case .LRDidChangeAccentColor:
			didChangeAccentColor()
		default:
			print("… but the app is not set to do anything after observing that notification.")
		}
	}
	
	@objc func didMergeFromAppleMusicLibrary(_ notification: Notification) {
		print("The class “\(Self.self)” should override didMergeFromAppleMusicLibrary(). We would call it at this point.")
//		loadSavedLibraryItems()
//		tableView.reloadData()
	}
	
	func didChangeAccentColor() {
		guard MPMediaLibrary.authorizationStatus() != .authorized else { return }
		tableView.reloadData()
	}
	
}
