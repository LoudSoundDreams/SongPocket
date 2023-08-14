//
//  MusicLibrary.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer
import CoreData
import OSLog

final class MusicLibrary {
	private init() {}
	static let shared = MusicLibrary()
	
	private var library: MPMediaLibrary? = nil
	let context = Database.viewContext
	
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
extension MusicLibrary {
	// Updates our database in a sensible way to reflect the fresh `SongInfo`s.
	func mergeChanges(
		toMatchInAnyOrder freshInfosInAnyOrder: [SongInfo]
	) {
		os_signpost(.begin, log: .merge, name: "Initial parse")
		let existingSongs = Song.allFetched(sorted: false, inAlbum: nil, context: context)
		
		let defaults = UserDefaults.standard
		let keyHasSaved = DefaultsKey.hasSavedDatabase.rawValue
		
		let hasSaved = defaults.bool(forKey: keyHasSaved) // Returns `false` if there’s no saved value
		let isFirstImport = !hasSaved
		
		// Find out which `Song`s we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the `SongInfo`s that we don’t have `Song`s for. We’ll create new `Song`s (and maybe new `Album`s and `Collection`s`) for them.
		var potentiallyOutdatedSongsAndFreshInfos: [(Song, SongInfo)] = [] // We’ll sort these eventually.
		var songsToDelete: [Song] = []
		
		var infosBySongID: Dictionary<SongID, SongInfo> = {
			let tuples = freshInfosInAnyOrder.map { info in (info.songID, info) }
			return Dictionary(uniqueKeysWithValues: tuples)
		}()
		
		existingSongs.forEach { existingSong in
			let songID = existingSong.persistentID
			if let potentiallyUpdatedInfo = infosBySongID[songID] {
				// We have an existing `Song` for this `SongInfo`. We might need to update it.
				potentiallyOutdatedSongsAndFreshInfos.append(
					(existingSong, potentiallyUpdatedInfo)
				)
				
				infosBySongID[songID] = nil
			} else {
				// This `Song` no longer corresponds to any `SongInfo`. We’ll delete it.
				songsToDelete.append(existingSong)
			}
		}
		// `infosBySongID` now holds the `SongInfo`s that we don’t have `Song`s for.
		let newInfos = infosBySongID.map { $0.value }
		os_signpost(.end, log: .merge, name: "Initial parse")
		
		updateLibraryItems( // Update before creating and deleting, so that we can easily put new `Song`s above modified `Song`s.
			// This also deletes all but one `Album` with any given `albumPersistentID`.
			// This might create `Album`s, but not `Collection`s or `Song`s.
			// This might delete `Album`s, but not `Collection`s or `Song`s.
			// This also might leave behind empty `Album`s. We don’t delete those here, so that if the user also added other `Song`s to those `Album`s, we can keep those `Album`s in the same place, instead of re-adding them to the top.
			potentiallyOutdatedSongsAndFreshInfos: potentiallyOutdatedSongsAndFreshInfos)
		
		let existingAlbums = Album.allFetched(sorted: false, inCollection: nil, context: context) // Order doesn’t matter, because we identify `Album`s by their `albumPersistentID`.
		let existingFolders = Collection.allFetched(sorted: true, context: context) // Order matters, because we’ll try to add new `Album`s to the first `Collection` with a matching title.
		createLibraryItems( // Create before deleting, because deleting also cleans up empty `Album`s and `Collection`s, which we shouldn’t do yet (see above).
			// This might create new `Album`s, and if it does, it might create new `Collection`s.
			for: newInfos,
			existingAlbums: existingAlbums,
			existingFolders: existingFolders,
			isFirstImport: isFirstImport)
		deleteLibraryItems(
			for: songsToDelete)
		
		cleanUpLibraryItems(
			allInfos: freshInfosInAnyOrder,
			isFirstImport: isFirstImport)
		
		context.tryToSave()
		
		defaults.set(
			true,
			forKey: keyHasSaved)
		
		DispatchQueue.main.async {
			NotificationCenter.default.post(
				name: .mergedChanges,
				object: nil)
		}
		
#if targetEnvironment(simulator)
		Sim_Global.currentSong = Song.allFetched(
			sorted: true,
			inAlbum: nil,
			context: context)
		.first { fetchedSong in
			fetchedSong.songInfo()?.songID == Sim_Global.currentSongID
		}
#endif
	}
}
