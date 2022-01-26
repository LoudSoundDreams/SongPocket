//
//  mergeChanges.swift
//  LavaRock
//
//  Created by h on 2020-08-15.
//

import CoreData
import OSLog

extension MusicLibraryManager {
	// Updates our database in a sensible way to reflect the fresh `SongFile`s.
	final func mergeChanges(toMatch freshSongFiles: [SongFile]) {
		os_signpost(.begin, log: .merge, name: "Initial parse")
		let existingSongs = Song.allFetched(ordered: false, via: context)
		
		let defaults = UserDefaults.standard
		let defaultsKeyHasEverImported = LRUserDefaultsKey.hasEverImportedFromMusic.rawValue
		
		let hasEverImportedFromMusic = defaults.bool(forKey: defaultsKeyHasEverImported) // Returns `false` if there's no saved value
		let isFirstImport = !hasEverImportedFromMusic
		
		// Find out which `Song`s we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the `SongFile`s that we don't have `Song`s for. We'll create new Songs (and maybe new Albums and Collections) for them.
		var potentiallyOutdatedSongsAndFreshSongFiles: [(Song, SongFile)] = [] // We'll sort these eventually.
		var songsToDelete: [Song] = []
		
		var songFilesByID: Dictionary<SongFileID, SongFile> = {
			let fileIDsAndFiles = freshSongFiles.map { songFile in (songFile.fileID, songFile) }
			return Dictionary(uniqueKeysWithValues: fileIDsAndFiles)
		}()
		
		existingSongs.forEach { existingSong in
			let songFileID = existingSong.persistentID
			if let potentiallyUpdatedSongFile = songFilesByID[songFileID] {
				// We have an existing `Song` for this `SongFile`. We might need to update it.
				potentiallyOutdatedSongsAndFreshSongFiles.append(
					(existingSong, potentiallyUpdatedSongFile)
				)
				
				songFilesByID[songFileID] = nil
			} else {
				// This `Song` no longer corresponds to any `SongFile`. We'll delete it.
				songsToDelete.append(existingSong)
			}
		}
		// `songFilesByID` now holds the `SongFile`s that we don't have `Song`s for.
		let newSongFiles = songFilesByID.map { $0.value }
		os_signpost(.end, log: .merge, name: "Initial parse")
		
		updateLibraryItems( // Update before creating and deleting, so that we can easily put new `Song`s above modified `Song`s.
			// This also deletes all but one `Album` with any given `albumPersistentID`.
			// This might create `Album`s, but not `Collection`s or `Song`s.
			// This might delete `Album`s, but not `Collection`s or `Song`s.
			// This also might leave behind empty `Album`s. We don't delete those here, so that if the user also added other `Song`s to those `Album`s, we can keep those `Album`s in the same place, instead of re-adding them to the top.
			potentiallyOutdatedSongsAndFreshSongFiles: potentiallyOutdatedSongsAndFreshSongFiles)
		
		let existingAlbums = Album.allFetched(ordered: false, via: context) // Order doesn't matter, because we identify `Album`s by their `albumPersistentID`.
		let existingCollections = Collection.allFetched(ordered: true, via: context) // Order matters, because we'll try to add new `Album`s to the first `Collection` with a matching title.
		createLibraryItems( // Create before deleting, because deleting also cleans up empty `Album`s and `Collection`s, which we shouldn't do yet (see above).
			// This might create new `Album`s, and if it does, it might create new `Collection`s.
			for: newSongFiles,
			existingAlbums: existingAlbums,
			existingCollections: existingCollections,
			isFirstImport: isFirstImport)
		deleteLibraryItems(
			for: songsToDelete)
		
		cleanUpLibraryItems(
			allSongFiles: freshSongFiles,
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
