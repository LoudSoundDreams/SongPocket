//
//  AppleMusicLibraryManager.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer
import OSLog

final class AppleMusicLibraryManager { // This is a class and not a struct because it should end observing notifications in a deinitializer.
	
	// MARK: - Properties
	
	// "Constants"
	static let shared = AppleMusicLibraryManager()
	private var library: MPMediaLibrary?
	var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	// Constants for debugging only
	static let subsystemForOSLog = "LavaRock.AppleMusicLibraryManager"
	static let importChangesMainLog = OSLog(
		subsystem: subsystemForOSLog,
		category: "0. Import Changes Main")
	
	// Variables
	var shouldNextImportBeSynchronous = false
	
	// MARK: - Setup and Teardown
	
	private init() { }
	
	func setUpLibraryIfAuthorized() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		library = MPMediaLibrary.default()
		importChanges()
		beginObservingAndGeneratingNotifications()
	}
	
	deinit {
		endObservingAndGeneratingNotifications()
	}
	
	// MARK: - Notifications
	
	// MARK: Setup and Teardown
	
	private func beginObservingAndGeneratingNotifications() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.MPMediaLibraryDidChange,
			object: nil)
		library?.beginGeneratingLibraryChangeNotifications()
	}
	
	private func endObservingAndGeneratingNotifications() {
		NotificationCenter.default.removeObserver(self)
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		library?.endGeneratingLibraryChangeNotifications()
	}
	
	// MARK: Responding
	
	@objc private func didObserve(_ notification: Notification) {
		switch notification.name {
		case .MPMediaLibraryDidChange:
			importChanges()
		default:
			print("\(Self.self) observed the notification: \(notification.name)")
			print("… but is not set to do anything after observing that notification.")
		}
	}
	
}
