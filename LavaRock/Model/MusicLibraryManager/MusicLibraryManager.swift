//
//  MusicLibraryManager.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer
import OSLog

final class MusicLibraryManager { // This is a class and not a struct because it should end observing notifications in a deinitializer.
	
	// MARK: - Properties
	
	// "Constants"
	static let shared = MusicLibraryManager()
	private var library: MPMediaLibrary?
	let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	// Constants for debugging only
	static let subsystemForOSLog = "LavaRock.MusicLibraryManager"
	static let importChangesMainLog = OSLog(
		subsystem: subsystemForOSLog,
		category: "0. Import Changes Main")
	
	// MARK: - Setup and Teardown
	
	private init() { }
	
	final func importChangesAndBeginGeneratingNotificationsIfAuthorized() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		library = MPMediaLibrary.default()
		importChanges()
		beginGeneratingNotifications()
	}
	
	deinit {
		endGeneratingNotifications()
	}
	
	// MARK: - Notifications
	
	private func beginGeneratingNotifications() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		NotificationCenter.default.removeObserver(self)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMediaLibraryDidChange,
			object: nil)
		library?.beginGeneratingLibraryChangeNotifications()
	}
	
	private func endGeneratingNotifications() {
		NotificationCenter.default.removeObserver(self)
		
		library?.endGeneratingLibraryChangeNotifications()
	}
	
	// MARK: Responding
	
	@objc private func didObserve(_ notification: Notification) {
		switch notification.name {
		case .MPMediaLibraryDidChange:
//			NotificationCenter.default.post(
//				Notification(name: Notification.Name.LRMediaLibraryDidChange)
//			)
			importChanges()
		default:
			print("\(Self.self) observed the notification: \(notification.name)")
			print("… but is not set to do anything after observing that notification.")
		}
	}
	
}
