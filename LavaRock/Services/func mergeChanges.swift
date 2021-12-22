//
//  func mergeChanges.swift
//  LavaRock
//
//  Created by h on 2020-08-15.
//

import CoreData
import MediaPlayer
import OSLog

extension MusicLibraryManager {
	
	// Keep our database matched up with the user’s library in the built-in Music app.
	final func mergeChanges() {
		os_signpost(.begin, log: .merge, name: "1. Merge changes")
		defer {
			os_signpost(.end, log: .merge, name: "1. Merge changes")
		}
		
		context.performAndWait {
			mergeChanges_()
		}
	}
	
	// WARNING: persistentIDs and albumPersistentIDs from Media Player are UInt64s, whereas we store them in Core Data as Int64s, so always use Int64(bitPattern: persistentID) when you deal with both Core Data and persistentIDs.
	private func mergeChanges_() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let queriedMediaItems = MPMediaQuery.songs().items
		else { return }
		
		os_signpost(.begin, log: .merge, name: "Initial parse")
		let existingSongs = Song.allFetched(ordered: false, via: context)
		
		let defaults = UserDefaults.standard
		let defaultsKeyHasEverImported = LRUserDefaultsKey.hasEverImportedFromMusic.rawValue
		let hasEverImportedFromMusic = defaults.bool(forKey: defaultsKeyHasEverImported) // Returns `false` if there's no saved value
		let isFirstImport = !hasEverImportedFromMusic
		
		// Find out which Songs we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the MPMediaItems that we don't have Songs for. We'll create new managed objects for them.
		var potentiallyOutdatedSongsAndFreshMediaItems: [(Song, MPMediaItem)] = [] // We'll sort these eventually.
		var songsToDelete: Set<Song> = []
		
		let tuplesForMediaItems = queriedMediaItems.map { mediaItem in
			(Int64(bitPattern: mediaItem.persistentID),
			 mediaItem)
		}
		var mediaItems_byInt64 = Dictionary(uniqueKeysWithValues: tuplesForMediaItems)
		
		existingSongs.forEach { existingSong in
			let persistentID_asInt64 = existingSong.persistentID
			if let potentiallyUpdatedMediaItem = mediaItems_byInt64[persistentID_asInt64] {
				// We have an existing Song for this MPMediaItem. We might need to update it.
				potentiallyOutdatedSongsAndFreshMediaItems.append(
					(existingSong,
					 potentiallyUpdatedMediaItem)
				)
				
				mediaItems_byInt64[persistentID_asInt64] = nil
			} else {
				// This Song no longer corresponds to any MPMediaItem in the Music library. We'll delete it.
				songsToDelete.insert(existingSong)
			}
		}
		// mediaItems_byInt64 now holds the MPMediaItems that we don't have Songs for. We'll create new Songs (and maybe new Albums and Collections) for them.
		let newMediaItems = mediaItems_byInt64.map { $0.value }
		os_signpost(.end, log: .merge, name: "Initial parse")
		
		updateLibraryItems( // Update before creating and deleting, so that we can easily put new Songs above modified Songs.
			// This also deletes all but one Album with any given albumPersistentID.
			// This might create Albums, but not Collections or Songs.
			// This might delete Albums, but not Collections or Songs.
			// This also might leave behind empty Albums, because all the Songs in them were moved to other Albums. We don't delete those empty Albums here, so that if the user also added other Songs to those Albums, we can keep those Albums in the same place, instead of re-adding them to the top.
			potentiallyOutdatedSongsAndFreshMediaItems: potentiallyOutdatedSongsAndFreshMediaItems)
		
		let existingAlbums = Album.allFetched(ordered: false, via: context) // Order doesn't matter, because we identify Albums by their albumPersistentID.
		let existingCollections = Collection.allFetched(via: context) // Order matters, because we'll try to add new Albums to the first Collection with a matching title.
		createLibraryItems( // Create before deleting, because deleting also cleans up empty Albums and Collections, which we shouldn't do yet, as mentioned above.
			// This might create new Albums, and if it does, it might create new Collections.
			for: newMediaItems,
			existingAlbums: existingAlbums,
			existingCollections: existingCollections,
			isFirstImport: isFirstImport)
		deleteLibraryItems(
			for: songsToDelete)
		
		os_signpost(.begin, log: .merge, name: "Convert Array to Set")
		let setOfQueriedMediaItems = Set(queriedMediaItems)
		os_signpost(.end, log: .merge, name: "Convert Array to Set")
		cleanUpLibraryItems(
			allMediaItems: setOfQueriedMediaItems,
			isFirstImport: isFirstImport)
		
		defaults.set(
			true,
			forKey: defaultsKeyHasEverImported)
		
		context.tryToSave()
		
		DispatchQueue.main.async {
			NotificationCenter.default.post(
				Notification(name: .LRDidMergeChanges)
			)
		}
	}
	
}
