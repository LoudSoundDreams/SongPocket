// 2020-09-22

import CoreData

extension MusicRepo {
	// Create new managed objects for the new `SongInfo`s, including new `Album`s and `Collection`s to put them in if necessary.
	func createLibraryItems(newInfos: [SongInfo], isFirstImport: Bool) {
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
	
	// MARK: Sort groups of `SongInfo`s
	
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
	
	// MARK: - Create groups of songs
	
	private func createSongsAndReturnNewAlbum(
		newInfos: [SongInfo],
		existingAlbums: [AlbumID: Album],
		isFirstImport: Bool
	) -> Album? {
		let firstInfo = newInfos.first!
		
		// If we already have a matching `Album` to add the `Song`s to…
		let albumID = firstInfo.albumID
		if let matchingExistingAlbum = existingAlbums[albumID] {
			// …then add the `Song`s to that `Album`.
			let songIDs = newInfos.map { $0.songID }
			if matchingExistingAlbum.songsAreInDefaultOrder() {
				matchingExistingAlbum.createSongsAtBeginning(with: songIDs)
				matchingExistingAlbum.sortSongsByDefaultOrder()
			} else {
				matchingExistingAlbum.createSongsAtBeginning(with: songIDs)
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
			newAlbum.createSongsAtEnd(with: sortedSongIDs)
			
			return newAlbum
		}
	}
	
	// MARK: Create containers
	
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
			return Album(atEndOf: collection, albumID: albumID, context: context)
		} else {
			return Album(atBeginningOf: collection, albumID: albumID, context: context)
		}
	}
}
