//
//  MusicRepo - Merge, Create.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData

extension MusicRepo {
	// Create new managed objects for the new `SongInfo`s, including new `Album`s and `Collection`s to put them in if necessary.
	func createLibraryItems(
		for newInfos: [SongInfo],
		existingAlbums: [Album],
		existingCollections: [Collection],
		isFirstImport: Bool
	) {
		func groupedByAlbumID(
			_ infos: [SongInfo]
		) -> [AlbumID: [SongInfo]] {
			return Dictionary(grouping: infos) { $0.albumID }
		}
		
		// Group the `SongInfo`s into albums, sorted by the order we’ll add them to our database in.
		let groupsOfInfos: [[SongInfo]] = {
			if isFirstImport {
				// Since our database is empty, we’ll add items from the top down, because it’s faster.
				let dictionary = groupedByAlbumID(newInfos)
				let groups = dictionary.map { $0.value }
				let sortedGroups = sortedByAlbumArtistNameThenAlbumTitle(groupsOfInfos: groups)
				// We’ll sort `Album`s by release date later.
				return sortedGroups
			} else {
				// Since our database isn’t empty, we’ll insert items at the top from the bottom up, because it’s simpler.
				let sortedInfos = newInfos.sorted { $0.dateAddedOnDisk < $1.dateAddedOnDisk }
				let dictionary = groupedByAlbumID(sortedInfos)
				let groupsOfSortedInfos = dictionary.map { $0.value }
				let sortedGroups = groupsOfSortedInfos.sorted { leftGroup, rightGroup in
					leftGroup.first!.dateAddedOnDisk < rightGroup.first!.dateAddedOnDisk
				}
				return sortedGroups
			}
			// We’ll sort `Song`s within each `Album` later, because it depends on whether the existing `Song`s in each `Album` are in album order.
		}()
		
		var existingAlbumsByID: Dictionary<AlbumID, Album> = {
			let tuplesForExistingAlbums = existingAlbums.map { album in
				(album.albumPersistentID, album)
			}
			return Dictionary(uniqueKeysWithValues: tuplesForExistingAlbums)
		}()
		var existingCollectionsByTitle: [String: [Collection]] =
		Dictionary(grouping: existingCollections) { $0.title! }
		
		groupsOfInfos.forEach { groupOfInfos in
			// Create one group of `Song`s and containers
			let (newAlbum, newCollection) = createSongsAndReturnNewContainers(
				for: groupOfInfos,
				existingAlbumsByID: existingAlbumsByID,
				existingCollectionsByTitle: existingCollectionsByTitle,
				isFirstImport: isFirstImport)
			
			if let newAlbum {
				existingAlbumsByID[newAlbum.albumPersistentID] = newAlbum
			}
			if let newCollection {
				let title = newCollection.title!
				let oldBucket = existingCollectionsByTitle[title] ?? []
				let newBucket = [newCollection] + oldBucket
				existingCollectionsByTitle[title] = newBucket
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
			guard
				let leftInfo = $0.first,
				let rightInfo = $1.first
			else {
				// Should never run
				return true
			}
			return leftInfo.precedesInDefaultOrder(inDifferentAlbum: rightInfo)
		}
		return sortedGroupsOfInfos
	}
	
	// MARK: - Create groups of songs
	
	private func createSongsAndReturnNewContainers(
		for infos: [SongInfo],
		existingAlbumsByID: [AlbumID: Album],
		existingCollectionsByTitle: [String: [Collection]],
		isFirstImport: Bool
	) -> (Album?, Collection?) {
		let firstInfo = infos.first!
		
		// If we already have a matching `Album` to add the `Song`s to…
		let albumID = firstInfo.albumID
		if let matchingExistingAlbum = existingAlbumsByID[albumID] {
			
			// …then add the `Song`s to that `Album`.
			let songIDs = infos.map { $0.songID }
			if matchingExistingAlbum.songsAreInDefaultOrder() {
				matchingExistingAlbum.createSongsAtBeginning(with: songIDs)
				matchingExistingAlbum.sortSongsByDefaultOrder()
			} else {
				matchingExistingAlbum.createSongsAtBeginning(with: songIDs)
			}
			
			return (nil, nil)
			
		} else {
			// Otherwise, create the `Album` to add the `Song`s to…
			let newContainers = newAlbumAndMaybeNewCollectionMade(
				for: firstInfo,
				existingCollectionsByTitle: existingCollectionsByTitle,
				isFirstImport: isFirstImport)
			let newAlbum = newContainers.album
			
			// …and then add the `Song`s to that `Album`.
			let sortedSongIDs = infos.sorted {
				$0.precedesInDefaultOrder(inSameAlbum: $1)
			}.map {
				$0.songID
			}
			newAlbum.createSongsAtEnd(with: sortedSongIDs)
			
			return newContainers
		}
	}
	
	// MARK: Create containers
	
	private func newAlbumAndMaybeNewCollectionMade(
		for newInfo: SongInfo,
		existingCollectionsByTitle: [String: [Collection]],
		isFirstImport: Bool
	) -> (album: Album, collection: Collection?) {
		let titleOfDestination
		= newInfo.albumArtistOnDisk ?? LRString.unknownArtist
		
		// If we already have a matching collection to put the album into…
		if let matchingExisting = existingCollectionsByTitle[titleOfDestination]?.first {
			
			// …then put the album in that collection.
			let newAlbum: Album = {
				if isFirstImport {
					return Album(
						atEndOf: matchingExisting,
						albumID: newInfo.albumID,
						context: context)
				} else {
					return Album(
						atBeginningOf: matchingExisting,
						albumID: newInfo.albumID,
						context: context)
				}}()
			
			return (newAlbum, nil)
			
		} else {
			// Otherwise, create the collection to put the album in…
			let newCollection: Collection = {
				if isFirstImport {
					let existingCount = existingCollectionsByTitle.reduce(0) { partialResult, entry in
						partialResult + entry.value.count
					}
					return Collection(
						afterAllOtherCount: existingCount,
						title: titleOfDestination,
						context: context)
				} else {
					// At the top
					return context.newCollection(index: 0, title: titleOfDestination)
				}
			}()
			
			// …and then put the album in that collection.
			let newAlbum = Album(
				atEndOf: newCollection,
				albumID: newInfo.albumID,
				context: context)
			
			return (newAlbum, newCollection)
		}
	}
}
