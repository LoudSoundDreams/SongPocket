//
//  func cleanUpManagedObjects.swift
//  LavaRock
//
//  Created by h on 2021-08-10.
//

import CoreData
import MediaPlayer
import OSLog

extension MusicLibraryManager {
	
	final func cleanUpManagedObjects(
		allMediaItems: Set<MPMediaItem>,
		isFirstImport: Bool
	) {
		os_signpost(.begin, log: importLog, name: "5. Cleanup")
		defer {
			os_signpost(.end, log: importLog, name: "5. Cleanup")
		}
		
		let allCollections = Collection.allFetched(ordered: false, context: context) // Order doesn't matter, because this is for reindexing the Albums within each Collection.
		let allAlbums = Album.allFetched(ordered: false, context: context) // Order doesn't matter, because this is for recalculating each Album's release date estimate, and reindexing the Songs within each Album.
		
		os_signpost(.begin, log: cleanupLog, name: "Recalculate Album release date estimates")
		recalculateReleaseDateEstimates(
			for: allAlbums,
			   considering: allMediaItems)
		os_signpost(.end, log: cleanupLog, name: "Recalculate Album release date estimates")
		
		os_signpost(.begin, log: cleanupLog, name: "Reindex all Albums and Songs")
		allCollections.forEach {
			reindexAlbums(
				in: $0,
				shouldSortByNewestFirst: isFirstImport)
		}
		allAlbums.forEach {
			reindexSongs(in: $0)
		}
		os_signpost(.end, log: cleanupLog, name: "Reindex all Albums and Songs")
	}
	
	// MARK: - Recalculating Release Date Estimates
	
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
			guard
				let matchingMediaItems = mediaItemsByAlbumPersistentID[
					MPMediaEntityPersistentID(bitPattern: album.albumPersistentID)
				]
			else {
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
	
	// MARK: - Reindexing
	
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
	
	// Verified as of build 154 on iOS 14.7 developer beta 5.
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
	
	private func reindexSongs(in album: Album) {
		var songsInAlbum = album.songs()
		
		songsInAlbum.reindex()
	}
	
}
