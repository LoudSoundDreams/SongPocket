//
//  cleanUpLibraryItems.swift
//  LavaRock
//
//  Created by h on 2021-08-10.
//

import CoreData
import OSLog

extension MusicLibraryManager {
	
	final func cleanUpLibraryItems(
		allSongFiles: [SongFile],
		isFirstImport: Bool
	) {
		os_signpost(.begin, log: .merge, name: "5. Clean up library items")
		defer {
			os_signpost(.end, log: .merge, name: "5. Clean up library items")
		}
		
		let allCollections = Collection.allFetched(ordered: false, via: context) // Order doesn't matter, because this is for reindexing the Albums within each Collection.
		let allAlbums = Album.allFetched(ordered: false, via: context) // Order doesn't matter, because this is for recalculating each Album's release date estimate, and reindexing the Songs within each Album.
		
		os_signpost(.begin, log: .cleanup, name: "Recalculate Album release date estimates")
		recalculateReleaseDateEstimates(
			for: allAlbums,
			   considering: allSongFiles)
		os_signpost(.end, log: .cleanup, name: "Recalculate Album release date estimates")
		
		os_signpost(.begin, log: .cleanup, name: "Reindex all Albums and Songs")
		allCollections.forEach {
			reindexAlbums(
				in: $0,
				shouldSortByNewestFirst: isFirstImport)
		}
		allAlbums.forEach {
			reindexSongs(in: $0)
		}
		os_signpost(.end, log: .cleanup, name: "Reindex all Albums and Songs")
	}
	
	// MARK: - Recalculating Release Date Estimates
	
	// Only `MPMediaItem`s have release dates, and those can’t be albums.
	// `MPMediaItemCollection.representativeItem.releaseDate` doesn’t necessarily represent the album’s release date.
	// Instead, use the most recent release date among the `MPMediaItemCollection`’s `MPMediaItem`s, and recalculate it whenever necessary.
	private func recalculateReleaseDateEstimates(
		for albums: [Album],
		considering songFiles: [SongFile]
	) {
		os_signpost(.begin, log: .cleanup, name: "Filter out SongFiles without release dates")
		// This is pretty slow, but can save time later.
		let songFilesWithReleaseDates = songFiles.filter { $0.releaseDateOnDisk != nil }
		os_signpost(.end, log: .cleanup, name: "Filter out SongFiles without release dates")
		
		os_signpost(.begin, log: .cleanup, name: "Group SongFiles by album")
		let songFilesByAlbumFolderID
		= Dictionary(grouping: songFilesWithReleaseDates) { $0.albumFolderID }
		os_signpost(.end, log: .cleanup, name: "Group SongFiles by album")
		
		albums.forEach { album in
			os_signpost(.begin, log: .cleanup, name: "Reestimate release date for one Album")
			defer {
				os_signpost(.end, log: .cleanup, name: "Reestimate release date for one Album")
			}
			
			album.releaseDateEstimate = nil
			
			os_signpost(.begin, log: .cleanup, name: "Find the release dates associated with this Album")
			// For Albums with no release dates, using `guard` to return early is slightly faster than optional chaining.
			guard let matchingSongFiles = songFilesByAlbumFolderID[album.albumPersistentID] else {
				os_signpost(.end, log: .cleanup, name: "Find the release dates associated with this Album")
				return
			}
			let matchingReleaseDates = matchingSongFiles.compactMap { $0.releaseDateOnDisk }
			os_signpost(.end, log: .cleanup, name: "Find the release dates associated with this Album")
			
			os_signpost(.begin, log: .cleanup, name: "Find the latest of those release dates")
			album.releaseDateEstimate = matchingReleaseDates.max()
			os_signpost(.end, log: .cleanup, name: "Find the latest of those release dates")
		}
	}
	
	// MARK: - Reindexing
	
	private func reindexAlbums(
		in collection: Collection,
		shouldSortByNewestFirst: Bool
	) {
		var albumsInCollection = collection.albums(sorted: true) // Sorted by index here, even if we're going to sort by release date later; this keeps Albums whose releaseDateEstimate is nil in their previous order.
		
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
		var songsInAlbum = album.songs(sorted: true)
		
		songsInAlbum.reindex()
	}
	
}
