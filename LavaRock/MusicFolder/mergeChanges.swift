//
//  mergeChanges.swift
//  LavaRock
//
//  Created by h on 2020-08-15.
//

import CoreData
import OSLog

extension Notification.Name {
	static var mergedChanges: Self {
		Self("merged changes")
	}
}

extension MusicLibrary {
	// Updates our database in a sensible way to reflect the fresh `SongMetadatum`s.
	func mergeChanges(
		toMatchInAnyOrder freshMetadataInAnyOrder: [SongMetadatum]
	) {
		os_signpost(.begin, log: .merge, name: "Initial parse")
		let existingSongs = Song.allFetched(sortedByIndex: false, via: context)
		
		let defaults = UserDefaults.standard
		let defaultsKeyHasEverImported = LRUserDefaultsKey.hasEverImportedFromMusic.rawValue
		
		let hasEverImportedFromMusic = defaults.bool(forKey: defaultsKeyHasEverImported) // Returns `false` if there’s no saved value
		let isFirstImport = !hasEverImportedFromMusic
		
		// Find out which `Song`s we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the `SongMetadatum`s that we don’t have `Song`s for. We’ll create new Songs (and maybe new Albums and Collections) for them.
		var potentiallyOutdatedSongsAndFreshMetadata: [(Song, SongMetadatum)] = [] // We’ll sort these eventually.
		var songsToDelete: [Song] = []
		
		var metadataBySongID: Dictionary<SongID, SongMetadatum> = {
			let tuples = freshMetadataInAnyOrder.map { metadatum in (metadatum.songID, metadatum) }
			return Dictionary(uniqueKeysWithValues: tuples)
		}()
		
		existingSongs.forEach { existingSong in
			let songID = existingSong.persistentID
			if let potentiallyUpdatedMetadatum = metadataBySongID[songID] {
				// We have an existing `Song` for this `SongMetadatum`. We might need to update it.
				potentiallyOutdatedSongsAndFreshMetadata.append(
					(existingSong, potentiallyUpdatedMetadatum)
				)
				
				metadataBySongID[songID] = nil
			} else {
				// This `Song` no longer corresponds to any `SongMetadatum`. We’ll delete it.
				songsToDelete.append(existingSong)
			}
		}
		// `metadataBySongID` now holds the `SongMetadatum`s that we don’t have `Song`s for.
		let newMetadata = metadataBySongID.map { $0.value }
		os_signpost(.end, log: .merge, name: "Initial parse")
		
		updateLibraryItems( // Update before creating and deleting, so that we can easily put new `Song`s above modified `Song`s.
			// This also deletes all but one `Album` with any given `albumPersistentID`.
			// This might create `Album`s, but not `Collection`s or `Song`s.
			// This might delete `Album`s, but not `Collection`s or `Song`s.
			// This also might leave behind empty `Album`s. We don’t delete those here, so that if the user also added other `Song`s to those `Album`s, we can keep those `Album`s in the same place, instead of re-adding them to the top.
			potentiallyOutdatedSongsAndFreshMetadata: potentiallyOutdatedSongsAndFreshMetadata)
		
		let existingAlbums = Album.allFetched(sortedByIndex: false, via: context) // Order doesn’t matter, because we identify `Album`s by their `albumPersistentID`.
		let existingCollections = Collection.allFetched(ordered: true, via: context) // Order matters, because we’ll try to add new `Album`s to the first `Collection` with a matching title.
		createLibraryItems( // Create before deleting, because deleting also cleans up empty `Album`s and `Collection`s, which we shouldn’t do yet (see above).
			// This might create new `Album`s, and if it does, it might create new `Collection`s.
			for: newMetadata,
			existingAlbums: existingAlbums,
			existingCollections: existingCollections,
			isFirstImport: isFirstImport)
		deleteLibraryItems(
			for: songsToDelete)
		
		cleanUpLibraryItems(
			allMetadata: freshMetadataInAnyOrder,
			isFirstImport: isFirstImport)
		
		defaults.set(
			true,
			forKey: defaultsKeyHasEverImported)
		
		context.tryToSave()
		
		DispatchQueue.main.async {
			NotificationCenter.default.post(
				name: .mergedChanges,
				object: nil)
		}
		
#if targetEnvironment(simulator)
		Sim_Global.songID = Song.allFetched(sortedByIndex: true, via: context).last?.metadatum()?.songID
#endif
	}
}
