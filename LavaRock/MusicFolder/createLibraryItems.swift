//
//  createLibraryItems.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import OSLog

extension MusicLibrary {
	// Create new managed objects for the new `SongInfo`s, including new `Album`s and `Collection`s to put them in if necessary.
	func createLibraryItems(
		for newInfos: [SongInfo],
		existingAlbums: [Album],
		existingCollections: [Collection],
		isFirstImport: Bool
	) {
		os_signpost(.begin, log: .merge, name: "3. Create library items")
		defer {
			os_signpost(.end, log: .merge, name: "3. Create library items")
		}
		
		func groupedByAlbumID(
			_ infos: [SongInfo]
		) -> [AlbumID: [SongInfo]] {
			os_signpost(.begin, log: .create, name: "Initial group")
			defer {
				os_signpost(.end, log: .create, name: "Initial group")
			}
			return Dictionary(grouping: infos) { $0.albumID }
		}
		
		// Group the `SongInfo`s into albums, sorted by the order we’ll add them to our database in.
		let groupsOfInfos: [[SongInfo]] = {
			if isFirstImport {
				// Since our database is empty, we’ll add items from the top down, because it’s faster.
				let dictionary = groupedByAlbumID(newInfos)
				let groups = dictionary.map { $0.value }
				os_signpost(.begin, log: .create, name: "Initial sort")
				let sortedGroups = sortedByAlbumArtistNameThenAlbumTitle(groupsOfInfos: groups)
				// We’ll sort `Album`s by release date later.
				os_signpost(.end, log: .create, name: "Initial sort")
				return sortedGroups
			} else {
				// Since our database isn’t empty, we’ll insert items at the top from the bottom up, because it’s simpler.
				os_signpost(.begin, log: .create, name: "Initial sort")
				let sortedInfos = newInfos.sorted { $0.dateAddedOnDisk < $1.dateAddedOnDisk }
				os_signpost(.end, log: .create, name: "Initial sort")
				let dictionary = groupedByAlbumID(sortedInfos)
				let groupsOfSortedInfos = dictionary.map { $0.value }
				os_signpost(.begin, log: .create, name: "Initial sort 2")
				let sortedGroups = groupsOfSortedInfos.sorted { leftGroup, rightGroup in
					leftGroup.first!.dateAddedOnDisk < rightGroup.first!.dateAddedOnDisk
				}
				os_signpost(.end, log: .create, name: "Initial sort 2")
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
		
		os_signpost(.begin, log: .create, name: "Create all the Songs and containers")
		groupsOfInfos.forEach { groupOfInfos in
			os_signpost(.begin, log: .create, name: "Create one group of Songs and containers")
			let (newAlbum, newCollection) = createSongsAndReturnNewContainers(
				for: groupOfInfos,
				existingAlbumsByID: existingAlbumsByID,
				existingCollectionsByTitle: existingCollectionsByTitle,
				isFirstImport: isFirstImport)
			
			if let newAlbum = newAlbum {
				existingAlbumsByID[newAlbum.albumPersistentID] = newAlbum
			}
			if let newCollection = newCollection {
				let title = newCollection.title!
				let oldBucketOfCollections = existingCollectionsByTitle[title] ?? []
				let newBucketOfCollections = [newCollection] + oldBucketOfCollections
				existingCollectionsByTitle[title] = newBucketOfCollections
			}
			os_signpost(.end, log: .create, name: "Create one group of Songs and containers")
		}
		os_signpost(.end, log: .create, name: "Create all the Songs and containers")
	}
	
	// MARK: Sorting Groups of `SongInfo`s
	
	// 1. Group by album artists, sorted alphabetically.
	// • “Unknown Album Artist” should go at the end.
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
	
	// MARK: - Creating Groups of Songs
	
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
				os_signpost(.begin, log: .create, name: "Put the existing Album back in order")
				matchingExistingAlbum.sortSongsByDefaultOrder()
				os_signpost(.end, log: .create, name: "Put the existing Album back in order")
			} else {
				matchingExistingAlbum.createSongsAtBeginning(with: songIDs)
			}
			
			return (nil, nil)
			
		} else {
			// Otherwise, create the `Album` to add the `Song`s to…
			os_signpost(.begin, log: .create, name: "Create a new album and maybe new folder")
			let newContainers = newAlbumAndMaybeNewFolderMade(
				for: firstInfo,
				existingCollectionsByTitle: existingCollectionsByTitle,
				isFirstImport: isFirstImport)
			let newAlbum = newContainers.album
			os_signpost(.end,log: .create, name: "Create a new album and maybe new folder")
			
			// …and then add the `Song`s to that `Album`.
			os_signpost(.begin, log: .create, name: "Sort the songs for the new album")
			let sortedSongIDs = infos.sorted {
				$0.precedesInDefaultOrder(inSameAlbum: $1)
			}.map {
				$0.songID
			}
			os_signpost(.end, log: .create, name: "Sort the songs for the new album")
			newAlbum.createSongsAtEnd(with: sortedSongIDs)
			
			return newContainers
		}
	}
	
	// MARK: Creating Containers
	
	private func newAlbumAndMaybeNewFolderMade(
		for newInfo: SongInfo,
		existingCollectionsByTitle: [String: [Collection]],
		isFirstImport: Bool
	) -> (album: Album, collection: Collection?) {
		let titleOfDestination
		= newInfo.albumArtistOnDisk ?? LRString.unknownAlbumArtist
		
		// If we already have a matching folder to put the album into…
		if let matchingExistingCollection = existingCollectionsByTitle[titleOfDestination]?.first {
			
			// …then put the album in that folder.
			let newAlbum: Album = {
				if isFirstImport {
					return Album(
						atEndOf: matchingExistingCollection,
						albumID: newInfo.albumID,
						context: context)
				} else {
					return Album(
						atBeginningOf: matchingExistingCollection,
						albumID: newInfo.albumID,
						context: context)
				}}()
			
			return (newAlbum, nil)
			
		} else {
			// Otherwise, create the folder to put the album in…
			let newCollection: Collection = {
				if isFirstImport {
					os_signpost(.begin, log: .create, name: "Count all the Collections so far")
					let existingCollectionsCount = existingCollectionsByTitle.reduce(0) { partialResult, entry in
						partialResult + entry.value.count
					}
					os_signpost(.end, log: .create, name: "Count all the Collections so far")
					return Collection(
						afterAllOtherCount: existingCollectionsCount,
						title: titleOfDestination,
						context: context)
				} else {
					let existingCollections = existingCollectionsByTitle.flatMap { $0.value }
					return Collection(
						index: 0,
						before: existingCollections,
						title: titleOfDestination,
						context: context)
				}}()
			
			// …and then put the album in that folder.
			let newAlbum = Album(
				atEndOf: newCollection,
				albumID: newInfo.albumID,
				context: context)
			
			return (newAlbum, newCollection)
		}
	}
}
