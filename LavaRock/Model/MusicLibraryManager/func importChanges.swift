//
//  func importChanges.swift
//  LavaRock
//
//  Created by h on 2020-08-15.
//

import CoreData
import MediaPlayer
import OSLog

extension MusicLibraryManager {
	
	// This is where the magic happens. This is the engine that keeps our data structures matched up with the library in the built-in Music app.
	final func importChanges() {
		os_signpost(.begin, log: importLog, name: "1. Import Changes Main")
		defer {
			os_signpost(.end, log: importLog, name: "1. Import Changes Main")
		}
		
		managedObjectContext.performAndWait {
			importChangesMethodBody()
		}
	}
	
	// Remember: persistentIDs and albumPersistentIDs from the MediaPlayer framework are UInt64s, whereas we store them in Core Data as Int64s, so always use Int64(bitPattern: persistentID) when you deal with both Core Data and persistentIDs.
	private func importChangesMethodBody() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let queriedMediaItems = MPMediaQuery.songs().items
		else { return }
		
		os_signpost(.begin, log: importLog, name: "Initial parse")
		let existingSongs = Song.allFetched(via: managedObjectContext, ordered: false)
		let shouldImportIntoDefaultOrder = existingSongs.isEmpty
		
		// Find out which Songs we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the MPMediaItems that we don't have Songs for. We'll make new managed objects for them.
		var songsToUpdateAndFreshMediaItems = [(Song, MPMediaItem)]() // We'll sort these eventually.
		var songsToDelete = Set<Song>()
		
		let mediaItemTuples = queriedMediaItems.map { mediaItem in
			(Int64(bitPattern: mediaItem.persistentID),
			 mediaItem)
		}
		var mediaItems_byInt64 = Dictionary(uniqueKeysWithValues: mediaItemTuples)
		
		existingSongs.forEach { existingSong in
			let persistentID_asInt64 = existingSong.persistentID
			if let potentiallyUpdatedMediaItem = mediaItems_byInt64[persistentID_asInt64] {
				// We have an existing Song for this MPMediaItem. We might need to update it.
				songsToUpdateAndFreshMediaItems.append(
					(existingSong, potentiallyUpdatedMediaItem)
				)
				
				mediaItems_byInt64[persistentID_asInt64] = nil
			} else {
				// This Song no longer corresponds to any MPMediaItem in the Music library. We'll delete it.
				songsToDelete.insert(existingSong)
			}
		}
		// mediaItems_byInt64 now holds the MPMediaItems that we don't have Songs for. We'll make new Songs (and maybe new Albums and Collections) for them.
		let newMediaItems = mediaItems_byInt64.map { $0.value }
		os_signpost(.end, log: importLog, name: "Initial parse")
		
		updateManagedObjects( // Update before creating and deleting, so that we can easily put new Songs above modified Songs.
			// This might make new Albums, but not new Collections or Songs.
			// This doesn't delete any Songs, Albums, or Collections.
			// This might also leave behind empty Albums, because all the Songs in them were moved to other Albums; but we won't delete those empty Albums for now, so that if the user also added other Songs to those empty Albums, we can keep those Albums in the same place, instead of re-adding them to the top.
			songsToUpdateAndFreshMediaItems: songsToUpdateAndFreshMediaItems)
		
		let existingAlbums = Album.allFetched(
			via: managedObjectContext,
			ordered: false) // Order doesn't matter, because we identify Albums by their albumPersistentID.
		let existingCollections = Collection.allFetched(via: managedObjectContext) // Order matters, because we'll try to add new Albums to the first Collection with a matching title.
		
		createManagedObjects( // Create before deleting, because deleting also cleans up empty Albums and Collections, which we shouldn't do yet, as mentioned above.
			// This might make new Albums, and if it does, it might make new Collections.
			for: newMediaItems,
			existingAlbums: existingAlbums,
			existingCollections: existingCollections)
		deleteManagedObjects(
			for: songsToDelete)
		
		os_signpost(.begin, log: importLog, name: "Convert Array to Set")
		let setOfQueriedMediaItems = Set(queriedMediaItems)
		os_signpost(.end, log: importLog, name: "Convert Array to Set")
		cleanUpManagedObjects(
			allMediaItems: setOfQueriedMediaItems,
			shouldImportIntoDefaultOrder: shouldImportIntoDefaultOrder)
		
		managedObjectContext.tryToSave()
//		managedObjectContext.parent!.tryToSave()
		DispatchQueue.main.async {
			NotificationCenter.default.post(
				Notification(name: .LRDidImportChanges)
			)
		}
	}
	
	// MARK: - Cleanup
	
	private func cleanUpManagedObjects(
		allMediaItems: Set<MPMediaItem>,
		shouldImportIntoDefaultOrder: Bool
	) {
		os_signpost(.begin, log: importLog, name: "5. Cleanup")
		
		let allCollections = Collection.allFetched(
			via: managedObjectContext,
			ordered: false) // Order doesn't matter, because this is for reindexing the Albums within each Collection.
		let allAlbums = Album.allFetched(
			via: managedObjectContext,
			ordered: false) // Order doesn't matter, because this is for recalculating each Album's release date estimate, and reindexing the Songs within each Album.
		
		os_signpost(.begin, log: cleanupLog, name: "Recalculate Album release date estimates")
		recalculateReleaseDateEstimates(
			for: allAlbums,
			   considering: allMediaItems)
		os_signpost(.end, log: cleanupLog, name: "Recalculate Album release date estimates")
		
		os_signpost(.begin, log: cleanupLog, name: "Reindex all Albums and Songs")
		allCollections.forEach {
			reindexAlbums(
				in: $0,
				shouldSortByNewestFirst: shouldImportIntoDefaultOrder)
		}
		allAlbums.forEach {
			reindexSongs(in: $0)
		}
		os_signpost(.end, log: cleanupLog, name: "Reindex all Albums and Songs")
		
		os_signpost(.end, log: importLog, name: "5. Cleanup")
	}
	
	// MARK: Recalculating Release Date Estimates
	
	// Only MPMediaItems have release dates, and those can't be albums.
	// An MPMediaItemCollection has a property representativeItem, but that item's release date doesn't necessarily represent the album's release date.
	// Instead, we'll estimate the albums' release dates and keep the estimates up to date.
	private func recalculateReleaseDateEstimates(
		for albums: [Album],
		considering mediaItems: Set<MPMediaItem>
	) {
		os_signpost(.begin, log: cleanupLog, name: "Filter out MPMediaItems without releaseDates")
		// This is pretty slow, but can save time later.
		let mediaItemsWithReleaseDates = mediaItems.filter { $0.releaseDate != nil }
		os_signpost(.end, log: cleanupLog, name: "Filter out MPMediaItems without releaseDates")
		
		// Note: We have a copy of this in createManagedObjects: groupedByAlbumPersistentID.
		os_signpost(.begin, log: cleanupLog, name: "Group MPMediaItems by albumPersistentID")
		let mediaItemsByAlbumPersistentID
		= Dictionary(grouping: mediaItemsWithReleaseDates) { $0.albumPersistentID }
		os_signpost(.end, log: cleanupLog, name: "Group MPMediaItems by albumPersistentID")
		
		albums.forEach { album in
			os_signpost(.begin, log: cleanupLog, name: "Recalculate release date estimate for one Album")
			defer {
				os_signpost(.end, log: cleanupLog, name: "Recalculate release date estimate for one Album")
			}
			
			album.releaseDateEstimate = nil
			
			os_signpost(.begin, log: cleanupLog, name: "Find the release dates associated with this Album")
			// For Albums with no release dates, using `guard` to return early is slightly faster than optional chaining.
			guard let matchingMediaItems = mediaItemsByAlbumPersistentID[
				MPMediaEntityPersistentID(bitPattern: album.albumPersistentID)
			] else {
				os_signpost(.end, log: cleanupLog, name: "Find the release dates associated with this Album")
				return
			}
			let matchingReleaseDates = matchingMediaItems.compactMap { $0.releaseDate }
			os_signpost(.end, log: cleanupLog, name: "Find the release dates associated with this Album")
			
			os_signpost(.begin, log: cleanupLog, name: "Find the latest of those release dates")
			let latestReleaseDate = matchingReleaseDates.max()
			album.releaseDateEstimate = latestReleaseDate
			os_signpost(.end, log: cleanupLog, name: "Find the latest of those release dates")
		}
	}
	
	// MARK: - Reindexing Albums
	
	private func reindexAlbums(
		in collection: Collection,
		shouldSortByNewestFirst: Bool
	) {
		var albumsInCollection = collection.albums() // Sorted by index here, even if we're going to sort by release date later; this keeps Albums whose releaseDateEstimate is nil in their previous order.
		
		if shouldSortByNewestFirst {
			albumsInCollection = sortedByNewestFirstAndUnknownReleaseDateLast(albumsInCollection)
		}
		
		albumsInCollection.reindex()
	}
	
	// Verified as of build 154 on iOS 14.7 beta 5.
	private func sortedByNewestFirstAndUnknownReleaseDateLast(
		_ albums: [Album]
	) -> [Album] {
		var albumsCopy = albums
		let commonDate = Date()
		albumsCopy.sort {
			// Reverses the order of all Albums whose releaseDateEstimate is nil.
			$0.releaseDateEstimate ?? commonDate
			>= $1.releaseDateEstimate ?? commonDate
		}
		albumsCopy.sort { _, rightAlbum in
			// Re-reverses the order of all Albums whose releaseDateEstimate is nil.
			rightAlbum.releaseDateEstimate == nil
		}
		return albumsCopy
	}
	
	// MARK: - Reindexing Songs
	
	private func reindexSongs(in album: Album) {
		var songsInAlbum = album.songs()
		
		songsInAlbum.reindex()
	}
	
}
