// 2021-08-10

import CoreData

extension MusicRepo {
	func cleanUpLibraryItems(
		songsToDelete: [Song],
		allInfos: [SongInfo],
		isFirstImport: Bool
	) {
		songsToDelete.forEach {
			context.delete($0)
			// WARNING: Leaves gaps in the `Song` indices within each `Album`, and might leave empty `Album`s. Later, you must delete empty `Album`s and reindex the `Song`s within each `Album`.
		}
		context.unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade()
		context.deleteEmptyCollections()
		
		let allAlbums = Album.allFetched(sorted: false, context: context) // Order doesn’t matter, because this is for recalculating each `Album`’s release date estimate, and reindexing the `Song`s within each `Album`.
		
		recalculateReleaseDateEstimates(for: allAlbums, considering: allInfos)
		
		Collection.allFetched(sorted: false, context: context).forEach {
			Self.reindexAlbums(in: $0, shouldSortByNewestFirst: isFirstImport)
		}
		allAlbums.forEach {
			let songs = $0.songs(sorted: true)
			Database.renumber(songs)
		}
	}
	
	// MARK: Re-estimate release date
	
	// Only `MPMediaItem`s have release dates, and those can’t be albums.
	// `MPMediaItemCollection.representativeItem.releaseDate` doesn’t necessarily represent the album’s release date.
	// Instead, use the most recent release date among the `MPMediaItemCollection`’s `MPMediaItem`s, and recalculate it whenever necessary.
	private func recalculateReleaseDateEstimates(
		for albums: [Album],
		considering infos: [SongInfo]
	) {
		// Filter out infos without release dates
		// This is pretty slow, but can save time later.
		let infosWithReleaseDates = infos.filter { $0.releaseDateOnDisk != nil }
		
		let infosByAlbumID: [AlbumID: [SongInfo]] =
		Dictionary(grouping: infosWithReleaseDates) { $0.albumID }
		
		albums.forEach { album in
			// Re-estimate release date for one `Album`
			
			album.releaseDateEstimate = nil
			
			// Find the release dates associated with this `Album`
			// For `Album`s with no release dates, using `guard` to return early is slightly faster than optional chaining.
			guard let matchingInfos = infosByAlbumID[album.albumPersistentID] else { return }
			let matchingReleaseDates = matchingInfos.compactMap { $0.releaseDateOnDisk }
			
			// Find the latest of those release dates
			album.releaseDateEstimate = matchingReleaseDates.max()
		}
	}
	
	// MARK: Reindex
	
	private static func reindexAlbums(
		in collection: Collection,
		shouldSortByNewestFirst: Bool
	) {
		var albumsInCollection = collection.albums(sorted: true) // Sorted by index here, even if we’re going to sort by release date later; this keeps `Album`s whose `releaseDateEstimate` is `nil` in their previous order.
		
		if shouldSortByNewestFirst {
			albumsInCollection = albumsInCollection.sortedMaintainingOrderWhen {
				$0.releaseDateEstimate == $1.releaseDateEstimate
			} areInOrder: {
				$0.precedesByNewestFirst($1)
			}
		}
		
		Database.renumber(albumsInCollection)
	}
}
