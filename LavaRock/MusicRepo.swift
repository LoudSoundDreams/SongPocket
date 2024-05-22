// 2020-08-10

import CoreData
import MediaPlayer

final class MusicRepo: ObservableObject {
	static let shared = MusicRepo()
	private init() {}
	@Published private(set) var signal_mergedChanges = false // Value doesn’t actually matter
	func watchMPLibrary() {
		library?.endGeneratingLibraryChangeNotifications()
		library = MPMediaLibrary.default()
		library?.beginGeneratingLibraryChangeNotifications()
		NotificationCenter.default.addObserverOnce(self, selector: #selector(mergeChanges), name: .MPMediaLibraryDidChange, object: library)
		mergeChanges()
	}
	
	private var library: MPMediaLibrary? = nil
	let context = Database.viewContext
	@objc private func mergeChanges() {
#if targetEnvironment(simulator)
		context.performAndWait {
			mergeChangesToMatch(freshInAnyOrder: Array(Sim_SongInfo.everyInfo.values))
		}
#else
		if let freshMediaItems = MPMediaQuery.songs().items {
			context.performAndWait {
				mergeChangesToMatch(freshInAnyOrder: freshMediaItems)
			}
		}
#endif
	}
	private func mergeChangesToMatch(freshInAnyOrder: [SongInfo]) {
		let defaults = UserDefaults.standard
		let keyHasSaved = LRDefaultsKey.hasSavedDatabase.rawValue
		
		let hasSaved = defaults.bool(forKey: keyHasSaved) // Returns `false` if there’s no saved value
		let isFirstImport = !hasSaved
		
		smooshAllCollections()
		
		// Find out which existing `Song`s we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the `SongInfo`s that we don’t have `Song`s for. We’ll create new `Song`s for them.
		let toUpdate: [(existing: Song, fresh: SongInfo)]
		let toDelete: [Song]
		let toCreate: [SongInfo]
		do {
			var updates: [(Song, SongInfo)] = []
			var deletes: [Song] = []
			
			var freshInfos: [SongID: SongInfo] = {
				let tuples = freshInAnyOrder.map { info in (info.songID, info) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			let existingSongs: [Song] = context.objectsFetched(for: Song.fetchRequest()) // Not sorted
			existingSongs.forEach { existingSong in
				let songID = existingSong.persistentID
				if let freshInfo = freshInfos[songID] {
					// We have an existing `Song` for this `SongInfo`. We might need to update the `Song`.
					updates.append((existingSong, freshInfo)) // We’ll sort these later.
					
					freshInfos[songID] = nil
				} else {
					// This `Song` no longer corresponds to any `SongInfo` in the library. We’ll delete it.
					deletes.append(existingSong)
				}
			}
			// `freshInfos` now holds the `SongInfo`s that we don’t have `Song`s for.
			
			toUpdate = updates
			toDelete = deletes
			toCreate = freshInfos.map { $0.value } // We’ll sort these later.
		}
		
		// Update before creating and deleting, so that we can easily put new `Song`s above modified `Song`s.
		// This also deletes all but one `Album` with any given `albumPersistentID`.
		// This might create `Album`s, but not `Collection`s or `Song`s.
		// This might delete `Album`s, but not `Collection`s or `Song`s.
		// This also might leave behind empty `Album`s. We don’t delete those here, so that if the user also added other `Song`s to those `Album`s, we can keep those `Album`s in the same place, instead of re-adding them to the top.
		updateLibraryItems(existingAndFresh: toUpdate)
		
		// Create before deleting, because deleting also cleans up empty `Album`s and `Collection`s, which we shouldn’t do yet (see above).
		// This might create new `Album`s, and if it does, it might create new `Collection`s.
		createLibraryItems(newInfos: toCreate, isFirstImport: isFirstImport)
		cleanUpLibraryItems(
			songsToDelete: toDelete,
			allInfos: freshInAnyOrder,
			isFirstImport: isFirstImport)
		
		context.tryToSave()
		
		defaults.set(true, forKey: keyHasSaved)
		
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: .LRMergedChanges, object: nil)
			self.signal_mergedChanges.toggle()
		}
	}
	
	// Databases created before version 2.5 can contain multiple `Collection`s, each with a non-default title.
	// Moves all `Album`s into the first `Collection`, and gives it the default title.
	private func smooshAllCollections() {
		let allCollections = Collection.allFetched(sorted: true, context: context)
		guard let firstCollection = allCollections.first else { return }
		
		firstCollection.title = LRString.tilde
		allCollections.dropFirst().forEach { laterCollection in
			laterCollection.albums(sorted: true).forEach { album in
				album.index = Int64(firstCollection.contents?.count ?? 0)
				album.container = firstCollection
			}
		}
		context.deleteEmptyCollections()
	}
	
	// MARK: - Update
	
	private func updateLibraryItems(existingAndFresh: [(Song, SongInfo)]) {
		// Merge `Album`s with the same `albumPersistentID`
		let canonicalAlbums: [AlbumID: Album] = mergeClonedAlbumsAndReturnCanonical(existingAndFresh: existingAndFresh)
		
		// Move `Song`s to updated `Album`s
		moveSongsToUpdatedAlbums(
			existingAndFresh: existingAndFresh.map { (song, info) in (song, info.albumID) },
			canonicalAlbums: canonicalAlbums)
	}
	
	private func mergeClonedAlbumsAndReturnCanonical(
		existingAndFresh: [(Song, SongInfo)]
	) -> [AlbumID: Album] {
		// I’ve seen an obscure bug where we had two `Album`s with the same `albumPersistentID`, probably caused by a bug in Apple Music for Mac when I was editing metadata. (Once, one song appeared twice in its album.)
		// We never should have had two `Album`s with the same `albumPersistentID`, but this code makes our database resilient to that problem.
		
		// To merge `Album`s with the same `albumPersistentID`, we’ll move their `Song`s into one `Album`, then delete empty `Album`s.
		// The one `Album` we’ll keep is the uppermost in the user’s custom order.
		let topmostUniqueAlbums: [AlbumID: Album] = {
			let allAlbums = Album.allFetched(sorted: true, context: context)
			let tuplesForAllAlbums = allAlbums.map { album in
				(album.albumPersistentID, album)
			}
			return Dictionary(tuplesForAllAlbums, uniquingKeysWith: { (leftAlbum, _) in leftAlbum })
		}()
		
		// Filter to `Song`s in cloned `Album`s
		// Don’t actually move any `Song`s, because we haven’t sorted them yet.
		let unsortedToMove: [Song] = existingAndFresh.compactMap { (song, _) in
			let album = song.container!
			let canonical = topmostUniqueAlbums[album.albumPersistentID]!
			guard canonical.objectID != album.objectID else { return nil }
			return song
		}
		
		// `Song`s will very rarely make it past this point.
		
		let toMove = unsortedToMove.sorted { $0.precedesInUserCustomOrder($1) }
		toMove.forEach { song in
			let destination = topmostUniqueAlbums[song.container!.albumPersistentID]!
			song.index = Int64(destination.contents?.count ?? 0)
			song.container = destination
		}
		
		context.unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade()
		
		return topmostUniqueAlbums
	}
	
	private func moveSongsToUpdatedAlbums(
		existingAndFresh: [(Song, AlbumID)],
		canonicalAlbums: [AlbumID: Album]
	) {
		// If a `Song`’s `Album.albumPersistentID` no longer matches the `Song`’s `SongInfo.albumID`, move that `Song` to an existing or new `Album` with the up-to-date `albumPersistentID`.
		let toUpdate: [(Song, AlbumID)] = {
			// Filter to `Song`s moved to different `Album`s
			let unsortedOutdated = existingAndFresh.filter { (song, albumID) in
				albumID != song.container!.albumPersistentID
			}
			// Sort by the order the user arranged the `Song`s in the app.
			return unsortedOutdated.sorted { leftTuple, rightTuple in
				leftTuple.0.precedesInUserCustomOrder(rightTuple.0)
			}
		}()
		var existingAlbums = canonicalAlbums
		toUpdate.reversed().forEach { (song, freshAlbumID) in
			// This `Song`’s `albumPersistentID` has changed. Move it to its up-to-date `Album`.
			// If we already have a matching `Album` to move the `Song` to…
			if let existingAlbum = existingAlbums[freshAlbumID] {
				// …then move the `Song` to that `Album`.
				existingAlbum.songs(sorted: false).forEach { $0.index += 1 }
				
				song.index = 0
				song.container = existingAlbum
			} else {
				// Otherwise, create the `Album` to move the `Song` to…
				let existingCollection = song.container!.container!
				let newAlbum = Album(atBeginningOf: existingCollection, albumID: freshAlbumID)
				
				// …and then move the `Song` to that `Album`.
				song.index = 0
				song.container = newAlbum
				
				// Make a note of the new `Album`.
				existingAlbums[freshAlbumID] = newAlbum
			}
		}
	}
	
	// MARK: - Create
	
	// Create new managed objects for the new `SongInfo`s, including new `Album`s and `Collection`s to put them in if necessary.
	private func createLibraryItems(newInfos: [SongInfo], isFirstImport: Bool) {
		func byAlbumID(infos: [SongInfo]) -> [AlbumID: [SongInfo]] {
			return Dictionary(grouping: infos) { $0.albumID }
		}
		
		// Group the `SongInfo`s into albums, sorted by the order we’ll add them to our database in.
		let groupsOfInfos: [[SongInfo]] = {
			if isFirstImport {
				// Since our database is empty, we’ll add items from the top down, because it’s faster.
				let dictionary = byAlbumID(infos: newInfos)
				let groups = dictionary.map { $0.value }
				let sortedGroups = sortedByAlbumArtistNameThenAlbumTitle(groupsOfInfos: groups)
				// We’ll sort `Album`s by release date later.
				return sortedGroups
			} else {
				// Since our database isn’t empty, we’ll insert items at the top from the bottom up, because it’s simpler.
				let sortedInfos = newInfos.sorted { $0.dateAddedOnDisk < $1.dateAddedOnDisk }
				let dictionary = byAlbumID(infos: sortedInfos)
				let groupsOfSortedInfos = dictionary.map { $0.value }
				let sortedGroups = groupsOfSortedInfos.sorted { leftGroup, rightGroup in
					leftGroup.first!.dateAddedOnDisk < rightGroup.first!.dateAddedOnDisk
				}
				return sortedGroups
			}
			// We’ll sort `Song`s within each `Album` later, because it depends on whether the existing `Song`s in each `Album` are in album order.
		}()
		
		var existingAlbums: [AlbumID: Album] = {
			let allAlbums = Album.allFetched(sorted: false, context: context)
			let tuples = allAlbums.map { ($0.albumPersistentID, $0) }
			return Dictionary(uniqueKeysWithValues: tuples)
		}()
		groupsOfInfos.forEach { groupOfInfos in
			// Create one group of `Song`s and containers
			if let newAlbum = createSongsAndReturnNewAlbum(
				newInfos: groupOfInfos,
				existingAlbums: existingAlbums,
				isFirstImport: isFirstImport
			) {
				existingAlbums[newAlbum.albumPersistentID] = newAlbum
			}
		}
	}
	
	// 1. Group by album artists, sorted alphabetically.
	// • “Unknown Artist” should go at the end.
	// 2. Within each album artist, group by albums, sorted by most recent first.
	private func sortedByAlbumArtistNameThenAlbumTitle(
		groupsOfInfos: [[SongInfo]]
	) -> [[SongInfo]] {
		let sortedGroupsOfInfos = groupsOfInfos.sorted {
			guard let leftInfo = $0.first, let rightInfo = $1.first else {
				// Should never run
				return true
			}
			return leftInfo.precedesInDefaultOrder(inDifferentAlbum: rightInfo)
		}
		return sortedGroupsOfInfos
	}
	
	// MARK: Create groups of songs
	
	private func createSongsAndReturnNewAlbum(
		newInfos: [SongInfo],
		existingAlbums: [AlbumID: Album],
		isFirstImport: Bool
	) -> Album? {
		let firstInfo = newInfos.first!
		
		// If we already have a matching `Album` to add the `Song`s to…
		let albumID = firstInfo.albumID
		if let existingAlbum = existingAlbums[albumID] {
			// …then add the `Song`s to that `Album`.
			let songIDs = newInfos.map { $0.songID }
			if existingAlbum.songsAreInDefaultOrder() {
				songIDs.reversed().forEach {
					let _ = Song(atBeginningOf: existingAlbum, songID: $0)
				}
				existingAlbum.sortSongsByDefaultOrder()
			} else {
				songIDs.reversed().forEach {
					let _ = Song(atBeginningOf: existingAlbum, songID: $0)
				}
			}
			
			return nil
		} else {
			// Otherwise, create the `Album` to add the `Song`s to…
			let newAlbum = createAlbum(albumID: firstInfo.albumID, isFirstImport: isFirstImport)
			
			// …and then add the `Song`s to that `Album`.
			let sortedSongIDs = newInfos.sorted {
				$0.precedesInDefaultOrder(inSameAlbum: $1)
			}.map {
				$0.songID
			}
			sortedSongIDs.forEach {
				let _ = Song(atEndOf: newAlbum, songID: $0)
			}
			
			return newAlbum
		}
	}
	private func createAlbum(albumID: AlbumID, isFirstImport: Bool) -> Album {
		let collection: Collection = {
			if let existing = Collection.allFetched(sorted: false, context: context).first {
				// Order doesn’t matter, because our database should contain exactly 0 or 1 `Collection`s at this point.
				return existing
			}
			let new = Collection(context: context)
			new.index = 0
			new.title = LRString.tilde
			return new
		}()
		if isFirstImport {
			return Album(atEndOf: collection, albumID: albumID)!
		} else {
			return Album(atBeginningOf: collection, albumID: albumID)!
		}
	}
	
	// MARK: - Clean Up
	
	private func cleanUpLibraryItems(
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
		
		Collection.allFetched(sorted: false, context: context).forEach { collection in
			// If this is the first import, sort `Album`s by newest first.
			// Always reindex all `Album`s, because we might have deleted some, which leaves gaps in the indices.
			let albums: [Album] = {
				let byIndex = collection.albums(sorted: true) // Sorted by index here, even if we’re going to sort by release date later; this keeps `Album`s whose `releaseDateEstimate` is `nil` in their previous order.
				guard isFirstImport else { return byIndex }
				return byIndex.sortedMaintainingOrderWhen {
					$0.releaseDateEstimate == $1.releaseDateEstimate
				} areInOrder: {
					$0.precedesByNewestFirst($1)
				}
			}()
			Database.renumber(albums)
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
}
