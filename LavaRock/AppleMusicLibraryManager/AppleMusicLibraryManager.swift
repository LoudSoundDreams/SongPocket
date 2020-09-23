//
//  AppleMusicLibraryManager.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer

final class AppleMusicLibraryManager {
	
	// MARK: - Properties
	
	// "Constants"
	static let shared = AppleMusicLibraryManager()
	private var library: MPMediaLibrary?
	var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
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
	
	// After observing notifications, funnel control flow through here, rather than calling methods directly, to make debugging easier.
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
