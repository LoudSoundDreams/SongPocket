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
			name: Notification.Name.LRWillSaveChangesFromAppleMusicLibrary,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.NSManagedObjectContextDidSave,
			object: managedObjectContext)
		
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
		print("An instance of \(Self.self) observed the notification: \(notification.name)")
		switch notification.name {
		case .LRWillSaveChangesFromAppleMusicLibrary:
			willSaveChangesFromAppleMusicLibrary(notification)
		case .NSManagedObjectContextDidSave:
			managedObjectContextDidSave(notification)
		case .LRDidChangeAccentColor:
			didChangeAccentColor()
		default:
			print("… but the app is not set to do anything after observing that notification.")
		}
	}
	
	func willSaveChangesFromAppleMusicLibrary(_ notification: Notification) {
		guard respondsToWillSaveChangesFromAppleMusicLibraryNotifications else { return }
		shouldRespondToNextManagedObjectContextDidSaveNotification = true
	}
	
	@objc func managedObjectContextDidSave(_ notification: Notification) {
		print("The class “\(Self.self)” should override managedObjectContextDidSave(_:). We would call it at this point.")
	}
	
	func didChangeAccentColor() {
		guard MPMediaLibrary.authorizationStatus() != .authorized else { return }
		tableView.reloadData()
	}
	
}
