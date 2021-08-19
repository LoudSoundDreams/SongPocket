//
//  MusicLibraryManager.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer
import OSLog

final class MusicLibraryManager { // This is a class and not a struct because it should end observing notifications in a deinitializer.
	
	private init() {}
	static let shared = MusicLibraryManager()
	
	// MARK: - Properties
	
	// For Instruments
	private static let subsystemName = "LavaRock.MusicLibraryManager"
	let importLog = OSLog(subsystem: subsystemName, category: "1. Main")
	let updateLog = OSLog(subsystem: subsystemName, category: "2. Update")
	let createLog = OSLog(subsystem: subsystemName, category: "3. Create")
	let deleteLog = OSLog(subsystem: subsystemName, category: "4. Delete")
	let cleanupLog = OSLog(subsystem: subsystemName, category: "5. Cleanup")
	
	let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	private var library: MPMediaLibrary?
	
	// MARK: - Setup and Teardown
	
	final func setUpAndImportChanges() {
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
			selector: #selector(mediaLibraryDidChange),
			name: Notification.Name.MPMediaLibraryDidChange,
			object: nil)
		library?.beginGeneratingLibraryChangeNotifications()
	}
	
	private func endGeneratingNotifications() {
		NotificationCenter.default.removeObserver(self)
		
		library?.endGeneratingLibraryChangeNotifications()
	}
	
	// MARK: Responding
	
	@objc private func mediaLibraryDidChange() {
		importChanges()
	}
	
}
