//
//  MusicFolder.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer
import OSLog

final class MusicFolder { // This is a class and not a struct because it needs a deinitializer.
	static let shared = MusicFolder()
	private init() {}
	
	let context = Database.viewContext
	
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
			object: library)
		
		mergeChanges()
	}
	@objc private func mediaLibraryDidChange() { mergeChanges() }
	
	private func mergeChanges() {
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
