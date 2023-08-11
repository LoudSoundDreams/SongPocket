//
//  MusicLibrary.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer
import OSLog

final class MusicLibrary {
	private init() {}
	static let shared = MusicLibrary()
	
	let context = Database.viewContext
	
	private var library: MPMediaLibrary? = nil
	
	func beginWatching() {
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
		
#if targetEnvironment(simulator)
		context.performAndWait {
			mergeChanges(toMatchInAnyOrder: Sim_SongInfo.all)
		}
#else
		let songsQuery = MPMediaQuery.songs()
		if let freshMediaItems = songsQuery.items {
			context.performAndWait {
				mergeChanges(toMatchInAnyOrder: freshMediaItems)
			}
		}
#endif
	}
	
	deinit {
		library?.endGeneratingLibraryChangeNotifications()
	}
}
