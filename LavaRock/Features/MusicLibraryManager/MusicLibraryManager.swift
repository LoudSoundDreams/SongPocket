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
	
	let context = Persistence.viewContext
	
	private var library: MPMediaLibrary? = nil
	
	final func setUpAndMergeChanges() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		library?.endGeneratingLibraryChangeNotifications()
		library = MPMediaLibrary.default()
		library?.beginGeneratingLibraryChangeNotifications()
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(mediaLibraryDidChange),
			name: .MPMediaLibraryDidChange,
			object: nil)
		
		mergeChanges()
	}
	@objc private func mediaLibraryDidChange() { mergeChanges() }
	
	final func mergeChanges() {
		os_signpost(.begin, log: .merge, name: "1. Merge changes")
		defer {
			os_signpost(.end, log: .merge, name: "1. Merge changes")
		}
		
		guard let freshMediaItems = MPMediaQuery.songs().items else { return }
		context.performAndWait {
			mergeChanges(toMatch: freshMediaItems)
		}
	}
	
	deinit {
		library?.endGeneratingLibraryChangeNotifications()
	}
}
