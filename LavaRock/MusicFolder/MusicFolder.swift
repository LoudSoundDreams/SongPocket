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
		
#if targetEnvironment(simulator)
		context.performAndWait {
			let walpurgisNightAlbumID = Sim_AlbumIDDispenser.takeNumber()
			mergeChanges(toMatch: (
				Enabling.sim_emptyLibrary
				? []
				: [
					Sim_SongMetadatum(
						albumID: walpurgisNightAlbumID,
						albumArtistOnDisk: "GFriend",
						albumTitleOnDisk: "回:Walpurgis Night",
						discCountOnDisk: 2,
						discNumberOnDisk: 1,
						trackNumberOnDisk: 1,
						titleOnDisk: "Amazingly few discotheques provide jukeboxes.",
						artistOnDisk: "Five Boxing Wizards",
						releaseDateOnDisk: .now,
						dateAddedOnDisk: .now),
					Sim_SongMetadatum(
						albumID: walpurgisNightAlbumID,
						albumArtistOnDisk: "GFriend",
						albumTitleOnDisk: "回:Walpurgis Night",
						discCountOnDisk: 1,
						discNumberOnDisk: 1,
						trackNumberOnDisk: 900,
						titleOnDisk: "Crossroads",
						artistOnDisk: "GFriend",
						releaseDateOnDisk: .now,
						dateAddedOnDisk: .now),
				]
			))
		}
#else
		if let freshMediaItems = MPMediaQuery.songs().items {
			context.performAndWait {
				mergeChanges(toMatch: freshMediaItems)
			}
		}
#endif
	}
	
	deinit {
		library?.endGeneratingLibraryChangeNotifications()
	}
}
