//
//  createLibraryItems.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import OSLog

extension MusicLibraryManager {
	// Create new managed objects for the new `SongFile`s, including new Albums and Collections to put them in if necessary.
	final func createLibraryItems(
		for newSongFiles: [SongFile],
		existingAlbums: [Album],
		existingCollections: [Collection],
		isFirstImport: Bool
	) {
		os_signpost(.begin, log: .merge, name: "3. Create library items")
		defer {
			os_signpost(.end, log: .merge, name: "3. Create library items")
		}
		
		func groupedByAlbumFolderID(
			_ songFiles: [SongFile]
		) -> [AlbumFolderID: [SongFile]] {
			os_signpost(.begin, log: .create, name: "Initial group")
			defer {
				os_signpost(.end, log: .create, name: "Initial group")
			}
			return Dictionary(grouping: songFiles) { $0.albumFolderID }
		}
		
		// Group the `SongFile`s into albums, sorted by the order we'll add them to our database in.
		let songFileGroups: [[SongFile]] = {
			if isFirstImport {
				// Since our database is empty, we'll add items from the top down, because it's faster.
				let dictionary = groupedByAlbumFolderID(newSongFiles)
				let groups = dictionary.map { $0.value }
				os_signpost(.begin, log: .create, name: "Initial sort")
				let sortedGroups = sortedByAlbumArtistNameThenAlbumTitle(songFileGroups: groups)
				// We'll sort Albums by release date later.
				os_signpost(.end, log: .create, name: "Initial sort")
				return sortedGroups
			} else {
				// Since our database isn't empty, we'll insert items at the top from the bottom up, because it's simpler.
				os_signpost(.begin, log: .create, name: "Initial sort")
				let sortedSongFiles = newSongFiles.sorted { $0.dateAddedOnDisk < $1.dateAddedOnDisk }
				os_signpost(.end, log: .create, name: "Initial sort")
				let dictionary = groupedByAlbumFolderID(sortedSongFiles)
				let groupsOfSortedSongFiles = dictionary.map { $0.value }
				os_signpost(.begin, log: .create, name: "Initial sort 2")
				let sortedGroups = groupsOfSortedSongFiles.sorted { leftGroup, rightGroup in
					leftGroup.first!.dateAddedOnDisk < rightGroup.first!.dateAddedOnDisk
				}
				os_signpost(.end, log: .create, name: "Initial sort 2")
				return sortedGroups
			}
			// We'll sort Songs within each Album later, because it depends on whether the existing Songs in each Album are in album order.
		}()
		
		var existingAlbumsByID: Dictionary<AlbumFolderID, Album> = {
			let tuplesForExistingAlbums = existingAlbums.map { album in
				(album.albumPersistentID, album)
			}
			return Dictionary(uniqueKeysWithValues: tuplesForExistingAlbums)
		}()
		var existingCollectionsByTitle = Dictionary(grouping: existingCollections) { $0.title! }
		
		os_signpost(.begin, log: .create, name: "Create all the Songs and containers")
		songFileGroups.forEach { songFileGroup in
			os_signpost(.begin, log: .create, name: "Create one group of Songs and containers")
			let (newAlbum, newCollection) = createSongsAndReturnNewContainers(
				for: songFileGroup,
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
	
	// MARK: Sorting Groups of `SongFile`s
	
	// 1. Group by album artists, sorted alphabetically.
	// - "Unknown Album Artist" should go at the end.
	// 2. Within each album artist, group by albums, sorted by most recent first.
	
	private func sortedByAlbumArtistNameThenAlbumTitle(
		songFileGroups: [[SongFile]]
	) -> [[SongFile]] {
		let sortedSongFileGroups = songFileGroups.sorted {
			guard
				let leftSongFile = $0.first,
				let rightSongFile = $1.first
			else {
				// Should never run
				return true
			}
			return leftSongFile.precedesInDefaultOrder(inDifferentAlbum: rightSongFile)
		}
		return sortedSongFileGroups
	}
	
	// MARK: - Creating Groups of Songs
	
	private func createSongsAndReturnNewContainers(
		for songFileGroup: [SongFile],
		existingAlbumsByID: [AlbumFolderID: Album],
		existingCollectionsByTitle: [String: [Collection]],
		isFirstImport: Bool
	) -> (Album?, Collection?) {
		let firstSongFileInAlbum = songFileGroup.first!
		
		// If we already have a matching Album to add the Songs to …
		let albumFolderID = firstSongFileInAlbum.albumFolderID
		if let matchingExistingAlbum = existingAlbumsByID[albumFolderID] {
			
			// … then add the Songs to that Album.
			if matchingExistingAlbum.songsAreInDefaultOrder() {
				matchingExistingAlbum.createSongsAtBeginning(for: songFileGroup)
				os_signpost(.begin, log: .create, name: "Put the existing Album back in order")
				matchingExistingAlbum.sortSongsByDefaultOrder()
				os_signpost(.end, log: .create, name: "Put the existing Album back in order")
			} else {
				matchingExistingAlbum.createSongsAtBeginning(for: songFileGroup)
			}
			
			return (nil, nil)
			
		} else {
			// Otherwise, create the Album to add the Songs to …
			os_signpost(.begin, log: .create, name: "Create a new Album and maybe new Collection")
			let newContainers = newAlbumAndMaybeNewCollectionMade(
				for: firstSongFileInAlbum,
				   existingCollectionsByTitle: existingCollectionsByTitle,
				   isFirstImport: isFirstImport)
			let newAlbum = newContainers.album
			os_signpost(.end,log: .create, name: "Create a new Album and maybe new Collection")
			
			// … and then add the Songs to that Album.
			os_signpost(.begin, log: .create, name: "Sort the Songs for the new Album")
			let sortedSongFileGroup = songFileGroup.sorted {
				$0.precedesInDefaultOrder(inSameAlbum: $1)
			}
			os_signpost(.end, log: .create, name: "Sort the Songs for the new Album")
			newAlbum.createSongsAtEnd(for: sortedSongFileGroup)
			
			return newContainers
		}
	}
	
	// MARK: Creating Containers
	
	private func newAlbumAndMaybeNewCollectionMade(
		for newSongFile: SongFile,
		existingCollectionsByTitle: [String: [Collection]],
		isFirstImport: Bool
	) -> (album: Album, collection: Collection?) {
		let titleOfDestinationCollection
		= newSongFile.albumArtistOnDisk ?? Album.unknownAlbumArtistPlaceholder
		
		// If we already have a matching `Collection` to put the `Album` into …
		if let matchingExistingCollection = existingCollectionsByTitle[titleOfDestinationCollection]?.first {
			
			// … then put the `Album` into that `Collection`.
			let newAlbum: Album = {
				if isFirstImport {
					return Album(
						atEndOf: matchingExistingCollection,
						albumFolderID: newSongFile.albumFolderID,
						context: context)
				} else {
					return Album(
						atBeginningOf: matchingExistingCollection,
						albumFolderID: newSongFile.albumFolderID,
						context: context)
				}
			}()
			
			return (newAlbum, nil)
			
		} else {
			// Otherwise, create the `Collection` to put the `Album` into …
			let newCollection: Collection = {
				if isFirstImport {
					os_signpost(.begin, log: .create, name: "Count all the Collections so far")
					let existingCollectionsCount = existingCollectionsByTitle.reduce(0) { partialResult, entry in
						partialResult + entry.value.count
					}
					os_signpost(.end, log: .create, name: "Count all the Collections so far")
					return Collection(
						afterAllOtherCollectionsCount: existingCollectionsCount,
						title: titleOfDestinationCollection,
						context: context)
				} else {
					let existingCollections = existingCollectionsByTitle.flatMap { $0.value }
					return Collection(
						index: 0,
						before: existingCollections,
						title: titleOfDestinationCollection,
						context: context)
				}
			}()
			
			// … and then put the `Album` into that `Collection`.
			let newAlbum = Album(
				atEndOf: newCollection,
				albumFolderID: newSongFile.albumFolderID,
				context: context)
			
			return (newAlbum, newCollection)
		}
	}
}
