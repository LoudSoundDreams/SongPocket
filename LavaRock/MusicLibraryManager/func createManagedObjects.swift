//
//  func createManagedObjects.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import MediaPlayer
import OSLog

extension MusicLibraryManager {
	
	// Create new managed objects for the new media items, including new Albums and Collections to put them in if necessary.
	final func createManagedObjects(
		for newMediaItems: [MPMediaItem],
		existingAlbums: [Album],
		existingCollections: [Collection],
		isFirstImport: Bool
	) {
		os_signpost(.begin, log: importLog, name: "3. Create Managed Objects")
		defer {
			os_signpost(.end, log: importLog, name: "3. Create Managed Objects")
		}
		
		// Group the MPMediaItems into albums, sorted by the order we'll add them to our database in.
		let mediaItemGroups: [[MPMediaItem]] = {
			if isFirstImport {
				// Since our database is empty, we'll add items from the top down, because it's faster.
				let dictionary = groupedByAlbumPersistentID(newMediaItems)
				let groups = dictionary.map { $0.value }
				os_signpost(.begin, log: createLog, name: "Initial sort")
				let sortedGroups = sortedByAlbumArtistNameThenAlbumTitle(mediaItemGroups: groups)
				// We'll sort Albums by release date later.
				os_signpost(.end, log: createLog, name: "Initial sort")
				return sortedGroups
			} else {
				// Since our database isn't empty, we'll insert items at the top from the bottom up, because it's simpler.
				os_signpost(.begin, log: createLog, name: "Initial sort")
				let sortedMediaItems = newMediaItems.sorted { $0.dateAdded < $1.dateAdded }
				os_signpost(.end, log: createLog, name: "Initial sort")
				let dictionary = groupedByAlbumPersistentID(sortedMediaItems)
				let groupsOfSortedMediaItems = dictionary.map { $0.value }
				os_signpost(.begin, log: createLog, name: "Initial sort 2")
				let sortedGroups = groupsOfSortedMediaItems.sorted { leftGroup, rightGroup in
					leftGroup.first!.dateAdded < rightGroup.first!.dateAdded
				}
				os_signpost(.end, log: createLog, name: "Initial sort 2")
				return sortedGroups
			}
			// We'll sort Songs within each Album later, because it depends on whether the existing Songs in each Album are in album order.
		}()
		
		let tuplesForExistingAlbums = existingAlbums.map { album in
			(album.albumPersistentID,
			 album)
		}
		var existingAlbums_byInt64 = Dictionary(uniqueKeysWithValues: tuplesForExistingAlbums)
		var existingCollectionsByTitle = Dictionary(grouping: existingCollections) { $0.title! }
		
		os_signpost(.begin, log: createLog, name: "Create all the Songs and containers")
		mediaItemGroups.forEach { mediaItemGroup in
			os_signpost(.begin, log: createLog, name: "Create one group of Songs and containers")
			let (newAlbum, newCollection) = createSongsAndReturnNewContainers(
				for: mediaItemGroup,
				   existingAlbums_byInt64: existingAlbums_byInt64,
				   existingCollectionsByTitle: existingCollectionsByTitle,
				   isFirstImport: isFirstImport)
			
			if let newAlbum = newAlbum {
				existingAlbums_byInt64[newAlbum.albumPersistentID] = newAlbum
			}
			if let newCollection = newCollection {
				let title = newCollection.title!
				let oldBucketOfCollections = existingCollectionsByTitle[title] ?? []
				let newBucketOfCollections = [newCollection] + oldBucketOfCollections
				existingCollectionsByTitle[title] = newBucketOfCollections
			}
			os_signpost(.end, log: createLog, name: "Create one group of Songs and containers")
		}
		os_signpost(.end, log: createLog, name: "Create all the Songs and containers")
	}
	
	// MARK: - Grouping MPMediaItems
	
	private func groupedByAlbumPersistentID(
		_ mediaItems: [MPMediaItem]
	) -> [MPMediaEntityPersistentID: [MPMediaItem]] {
		os_signpost(.begin, log: createLog, name: "Initial group")
		defer {
			os_signpost(.end, log: createLog, name: "Initial group")
		}
		
		return Dictionary(grouping: mediaItems) { $0.albumPersistentID }
	}
	
	// MARK: Sorting Groups of MPMediaItems
	
	// 1. Group by album artists, sorted alphabetically.
	// - "Unknown Album Artist" should go at the end.
	// 2. Within each album artist, group by albums, sorted by most recent first.
	
	private func sortedByAlbumArtistNameThenAlbumTitle(
		mediaItemGroups: [[MPMediaItem]]
	) -> [[MPMediaItem]] {
		let sortedMediaItemGroups = mediaItemGroups.sorted {
			guard
				let leftMediaItem = $0.first,
				let rightMediaItem = $1.first
			else {
				// Should never run
				return true
			}
			return leftMediaItem.precedesInDefaultOrder(inDifferentAlbum: rightMediaItem)
		}
		return sortedMediaItemGroups
	}
	
	// MARK: - Creating Groups of Songs
	
	private func createSongsAndReturnNewContainers(
		for mediaItemGroup: [MPMediaItem],
		existingAlbums_byInt64: [Int64: Album],
		existingCollectionsByTitle: [String: [Collection]],
		isFirstImport: Bool
	) -> (Album?, Collection?) {
		let firstMediaItemInAlbum = mediaItemGroup.first!
		
		// If we already have a matching Album to add the Songs to …
		let albumPersistentID_asInt64 = Int64(bitPattern: firstMediaItemInAlbum.albumPersistentID)
		if let matchingExistingAlbum = existingAlbums_byInt64[albumPersistentID_asInt64] {
			
			// … then add the Songs to that Album.
			if matchingExistingAlbum.songsAreInDefaultOrder() {
				matchingExistingAlbum.createSongsAtBeginning(for: mediaItemGroup)
				os_signpost(.begin, log: createLog, name: "Put the existing Album back in order")
				matchingExistingAlbum.sortSongsByDefaultOrder()
				os_signpost(.end, log: createLog, name: "Put the existing Album back in order")
			} else {
				matchingExistingAlbum.createSongsAtBeginning(for: mediaItemGroup)
			}
			
			return (nil, nil)
			
		} else {
			// Otherwise, create the Album to add the Songs to …
			os_signpost(.begin, log: createLog, name: "Create a new Album and maybe new Collection")
			let newContainers = newAlbumAndMaybeNewCollectionMade(
				for: firstMediaItemInAlbum,
				   existingCollectionsByTitle: existingCollectionsByTitle,
				   isFirstImport: isFirstImport)
			let newAlbum = newContainers.album
			os_signpost(.end,log: createLog, name: "Create a new Album and maybe new Collection")
			
			// … and then add the Songs to that Album.
			os_signpost(.begin, log: createLog, name: "Sort the Songs for the new Album")
			let sortedMediaItemGroup = mediaItemGroup.sorted {
				$0.precedesInDefaultOrder(inSameAlbum: $1)
			}
			os_signpost(.end, log: createLog, name: "Sort the Songs for the new Album")
			newAlbum.createSongsAtEnd(for: sortedMediaItemGroup)
			
			return newContainers
		}
	}
	
	// MARK: Creating Containers
	
	private func newAlbumAndMaybeNewCollectionMade(
		for newMediaItem: MPMediaItem,
		existingCollectionsByTitle: [String: [Collection]],
		isFirstImport: Bool
	) -> (album: Album, collection: Collection?) {
		let titleOfDestinationCollection
		= newMediaItem.albumArtist ?? Album.unknownAlbumArtistPlaceholder
		
		// If we already have a matching `Collection` to put the `Album` into …
		if let matchingExistingCollection = existingCollectionsByTitle[titleOfDestinationCollection]?.first {
			
			// … then put the `Album` into that `Collection`.
			let newAlbum: Album = {
				if isFirstImport {
					return Album(
						atEndOf: matchingExistingCollection,
						for: newMediaItem,
						context: context)
				} else {
					return Album(
						atBeginningOf: matchingExistingCollection,
						for: newMediaItem,
						context: context)
				}
			}()
			
			return (newAlbum, nil)
			
		} else {
			// Otherwise, create the `Collection` to put the `Album` into …
			let newCollection: Collection = {
				if isFirstImport {
					os_signpost(.begin, log: createLog, name: "Count all the Collections so far")
					let existingCollectionsCount = existingCollectionsByTitle.reduce(0) { partialResult, entry in
						partialResult + entry.value.count
					}
					os_signpost(.end, log: createLog, name: "Count all the Collections so far")
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
				for: newMediaItem,
				context: context)
			
			return (newAlbum, newCollection)
		}
	}
	
}
