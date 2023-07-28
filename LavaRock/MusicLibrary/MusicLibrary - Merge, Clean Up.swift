//
//  MusicLibrary - Merge, Clean Up.swift
//  LavaRock
//
//  Created by h on 2021-08-10.
//

import CoreData
import OSLog

extension MusicLibrary {
	func cleanUpLibraryItems(
		allInfos: [SongInfo],
		isFirstImport: Bool
	) {
		os_signpost(.begin, log: .merge, name: "5. Clean up library items")
		defer {
			os_signpost(.end, log: .merge, name: "5. Clean up library items")
		}
		
		let allFolders = Collection.allFetched(ordered: false, via: context) // Order doesn’t matter, because this is for reindexing the albums within each folder.
		let allAlbums = Album.allFetched(sortedByIndex: false, via: context) // Order doesn’t matter, because this is for recalculating each `Album`’s release date estimate, and reindexing the `Song`s within each `Album`.
		
		os_signpost(.begin, log: .cleanup, name: "Recalculate Album release date estimates")
		recalculateReleaseDateEstimates(
			for: allAlbums,
			considering: allInfos)
		os_signpost(.end, log: .cleanup, name: "Recalculate Album release date estimates")
		
		os_signpost(.begin, log: .cleanup, name: "Reindex all Albums and Songs")
		allFolders.forEach {
			reindexAlbums(
				in: $0,
				shouldSortByNewestFirst: isFirstImport)
		}
		allAlbums.forEach {
			reindexSongs(in: $0)
		}
		os_signpost(.end, log: .cleanup, name: "Reindex all Albums and Songs")
	}
	
	// MARK: Re-estimate release date
	
	// Only `MPMediaItem`s have release dates, and those can’t be albums.
	// `MPMediaItemCollection.representativeItem.releaseDate` doesn’t necessarily represent the album’s release date.
	// Instead, use the most recent release date among the `MPMediaItemCollection`’s `MPMediaItem`s, and recalculate it whenever necessary.
	private func recalculateReleaseDateEstimates(
		for albums: [Album],
		considering infos: [SongInfo]
	) {
		os_signpost(.begin, log: .cleanup, name: "Filter out infos without release dates")
		// This is pretty slow, but can save time later.
		let infosWithReleaseDates = infos.filter { $0.releaseDateOnDisk != nil }
		os_signpost(.end, log: .cleanup, name: "Filter out infos without release dates")
		
		os_signpost(.begin, log: .cleanup, name: "Group infos by album")
		let infosByAlbumID: [AlbumID: [SongInfo]] =
		Dictionary(grouping: infosWithReleaseDates) { $0.albumID }
		os_signpost(.end, log: .cleanup, name: "Group infos by album")
		
		albums.forEach { album in
			os_signpost(.begin, log: .cleanup, name: "Re-estimate release date for one Album")
			defer {
				os_signpost(.end, log: .cleanup, name: "Re-estimate release date for one Album")
			}
			
			album.releaseDateEstimate = nil
			
			os_signpost(.begin, log: .cleanup, name: "Find the release dates associated with this Album")
			// For `Album`s with no release dates, using `guard` to return early is slightly faster than optional chaining.
			guard let matchingInfos = infosByAlbumID[album.albumPersistentID] else {
				os_signpost(.end, log: .cleanup, name: "Find the release dates associated with this Album")
				return
			}
			let matchingReleaseDates = matchingInfos.compactMap { $0.releaseDateOnDisk }
			os_signpost(.end, log: .cleanup, name: "Find the release dates associated with this Album")
			
			os_signpost(.begin, log: .cleanup, name: "Find the latest of those release dates")
			album.releaseDateEstimate = matchingReleaseDates.max()
			os_signpost(.end, log: .cleanup, name: "Find the latest of those release dates")
		}
	}
	
	// MARK: Reindex
	
	private func reindexAlbums(
		in folder: Collection,
		shouldSortByNewestFirst: Bool
	) {
		var albumsInFolder = folder.albums(sorted: true) // Sorted by index here, even if we’re going to sort by release date later; this keeps `Album`s whose `releaseDateEstimate` is `nil` in their previous order.
		
		if shouldSortByNewestFirst {
			albumsInFolder = sortedByNewestFirstAndUnknownReleaseDateLast(albumsInFolder)
		}
		
		albumsInFolder.reindex()
	}
	
	private func sortedByNewestFirstAndUnknownReleaseDateLast(
		_ albums: [Album]
	) -> [Album] {
		var albumsCopy = albums
		let commonDate = Date()
		albumsCopy.sort {
			// Reverses the order of all `Album`s whose `releaseDateEstimate` is `nil`.
			$0.releaseDateEstimate ?? commonDate
			>= $1.releaseDateEstimate ?? commonDate
		}
		albumsCopy.sort { _, rightAlbum in
			// Re-reverses the order of all `Album`s whose `releaseDateEstimate` is `nil`.
			rightAlbum.releaseDateEstimate == nil
		}
		return albumsCopy
	}
	
	private func reindexSongs(in album: Album) {
		var songsInAlbum = album.songs(sorted: true)
		
		songsInAlbum.reindex()
	}
}
