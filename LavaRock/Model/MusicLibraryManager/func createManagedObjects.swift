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
	
	// Make new managed objects for the new media items, including new Albums and Collections to put them in if necessary.
	final func createManagedObjects(
		for newMediaItems: Set<MPMediaItem>,
		existingAlbums: [Album],
		existingCollections: [Collection]
	) {
		os_signpost(.begin, log: importLog, name: "3. Create Managed Objects")
		defer {
			os_signpost(.end, log: importLog, name: "3. Create Managed Objects")
		}
		
		let shouldImportIntoDefaultOrder = existingCollections.isEmpty
		
		// Group the MPMediaItems into albums, sorted by the order we'll add them to our database in.
		let mediaItemGroups: [[MPMediaItem]] = {
			if shouldImportIntoDefaultOrder {
				// Since our database is empty, we'll add items from the top down, because it's faster.
				let dictionary = groupedByAlbumPersistentID(Array(newMediaItems))
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
		
		let entriesForExistingAlbums = existingAlbums.map {
			(MPMediaEntityPersistentID(bitPattern: $0.albumPersistentID),
			 $0)
		}
		var existingAlbumsByAlbumPersistentID
		= Dictionary(uniqueKeysWithValues: entriesForExistingAlbums)
		let entriesForExistingCollections = existingCollections.map {
			($0.title!,
			$0)
		}
		var existingCollectionsByTitle
		= Dictionary(uniqueKeysWithValues: entriesForExistingCollections)
		
		os_signpost(.begin, log: createLog, name: "Make all the Songs and containers")
		mediaItemGroups.forEach { mediaItemGroup in
			os_signpost(.begin, log: createLog, name: "Make one group of Songs and containers")
			let (newAlbum, newCollection) = createSongsAndReturnNewContainers(
				for: mediaItemGroup,
				   existingAlbums: existingAlbumsByAlbumPersistentID,
				   existingCollections: existingCollectionsByTitle,
				   shouldImportIntoDefaultOrder: shouldImportIntoDefaultOrder)
			
			if let newAlbum = newAlbum {
				existingAlbumsByAlbumPersistentID[
					MPMediaEntityPersistentID(bitPattern: newAlbum.albumPersistentID)
				] = newAlbum
			}
			if let newCollection = newCollection {
				existingCollectionsByTitle[newCollection.title!] = newCollection
			}
			os_signpost(.end, log: createLog, name: "Make one group of Songs and containers")
		}
		os_signpost(.end, log: createLog, name: "Make all the Songs and containers")
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
			return leftMediaItem.precedesForImporterDisplayOrderOfAlbums(inDifferentAlbum: rightMediaItem)
		}
		return sortedMediaItemGroups
	}
	
	// MARK: - Creating Groups of Songs
	
	private func createSongsAndReturnNewContainers(
		for mediaItemGroup: [MPMediaItem],
		existingAlbums: [MPMediaEntityPersistentID: Album],
		existingCollections: [String: Collection],
		shouldImportIntoDefaultOrder: Bool
	) -> (Album?, Collection?) {
		let firstMediaItemInAlbum = mediaItemGroup.first!
		
		// If we already have a matching Album to add the Songs to …
		if let matchingExistingAlbum = existingAlbums[firstMediaItemInAlbum.albumPersistentID] {
			
			// … then add the Songs to that Album.
			if areSongsInAlbumDisplayOrder(in: matchingExistingAlbum) {
				createSongs(
					for: mediaItemGroup,
					   atEndOf: matchingExistingAlbum)
				os_signpost(.begin, log: createLog, name: "Put the existing Album back in order")
				matchingExistingAlbum.sortSongsByDisplayOrder()
				os_signpost(.end, log: createLog, name: "Put the existing Album back in order")
			} else {
				createSongs(
					for: mediaItemGroup,
					atBeginningOf: matchingExistingAlbum)
			}
			
			return (nil, nil)
			
		} else {
			// Otherwise, make the Album to add the Songs to …
			os_signpost(.begin, log: createLog, name: "Create a new Album and maybe new Collection")
			let newContainers = newAlbumAndMaybeNewCollectionMade(
				for: firstMediaItemInAlbum,
				existingCollections: existingCollections,
				shouldImportIntoDefaultOrder: shouldImportIntoDefaultOrder)
			let newAlbum = newContainers.album
			os_signpost(.end,log: createLog, name: "Create a new Album and maybe new Collection")
			
			// … and then add the Songs to that Album.
			os_signpost(.begin, log: createLog, name: "Sort the Songs for the new Album")
			let sortedMediaItemGroup = sortedByAlbumDisplayOrder(mediaItems: mediaItemGroup)
			os_signpost(.end, log: createLog, name: "Sort the Songs for the new Album")
			createSongs(
				for: sortedMediaItemGroup,
				   atEndOf: newAlbum)
			
			return newContainers
		}
	}
	
	// MARK: Creating Songs
	
	private func createSongs(
		for newMediaItems: [MPMediaItem],
		atEndOf album: Album
	) {
		os_signpost(.begin, log: createLog, name: "Make Songs at the bottom")
		defer {
			os_signpost(.end, log: createLog, name: "Make Songs at the bottom")
		}
		
		newMediaItems.forEach {
			let newSong = Song(context: managedObjectContext)
			newSong.persistentID = Int64(bitPattern: $0.persistentID)
			newSong.index = Int64(album.contents?.count ?? 0)
			newSong.container = album
		}
	}
	
	// Use createSongs(for:atEndOf:) if possible. It's faster.
	private func createSongs(
		for newMediaItems: [MPMediaItem],
		atBeginningOf album: Album
	) {
		os_signpost(.begin, log: createLog, name: "Make Songs at the top")
		defer {
			os_signpost(.end, log: createLog, name: "Make Songs at the top")
		}
		
		newMediaItems.reversed().forEach {
			let existingSongs = album.songs(sorted: false)
			existingSongs.forEach { $0.index += 1 }
			
			let newSong = Song(context: managedObjectContext)
			newSong.persistentID = Int64(bitPattern: $0.persistentID)
			newSong.index = 0
			newSong.container = album
		}
	}
	
	// MARK: - Sorting MPMediaItems
	
	private func sortedByAlbumDisplayOrder(mediaItems: [MPMediaItem]) -> [MPMediaItem] {
		return mediaItems.sorted { $0.precedesForImporterDisplayOrderOfSongs(inSameAlbum: $1) }
	}
	
	// MARK: - Sorting Saved Songs
	
	private func areSongsInAlbumDisplayOrder(in album: Album) -> Bool {
		let songs = album.songs()
		let mediaItems = songs.compactMap { $0.mpMediaItem() }
		// mpMediaItem() returns nil if the media item is no longer in the Music library. Don't let Songs that we'll delete later disrupt an otherwise in-order Album; just skip over them.
		
		let sortedMediaItems = sortedByAlbumDisplayOrder(mediaItems: mediaItems)
		
		return mediaItems == sortedMediaItems
	}
	
	// MARK: - Creating Containers
	
	private func newAlbumAndMaybeNewCollectionMade(
		for newMediaItem: MPMediaItem,
		existingCollections: [String: Collection],
		shouldImportIntoDefaultOrder: Bool
	) -> (album: Album, collection: Collection?) {
		// If we already have a matching Collection to add the Album to …
		let collectionTitleToLookUp
		= newMediaItem.albumArtist ?? Album.placeholderAlbumArtist
		if let matchingExistingCollection = existingCollections[collectionTitleToLookUp] {
			
			// … then add the Album to that Collection.
			let newAlbum: Album = {
				if shouldImportIntoDefaultOrder {
					return newAlbumMade(
						for: newMediaItem,
						   atEndOf: matchingExistingCollection)
				} else {
					return newAlbumMade(
						for: newMediaItem,
						   atBeginningOf: matchingExistingCollection)
				}
			}()
			
			return (newAlbum, nil)
			
		} else {
			// Otherwise, make the Collection to add the Album to …
			let newCollection: Collection = {
				if shouldImportIntoDefaultOrder {
					return newCollectionMade(
						for: newMediaItem,
						   afterAllExistingCollectionsCount: existingCollections.count)
				} else {
					let collections = existingCollections.map { $0.value }
					return newCollectionMade(
						for: newMediaItem,
						   above: collections)
				}
			}()
			
			// … and then add the Album to that Collection.
			let newAlbum = newAlbumMade(
				for: newMediaItem,
				   atEndOf: newCollection)
			
			return (newAlbum, newCollection)
		}
	}
	
	private func newAlbumMade(
		for newMediaItem: MPMediaItem,
		atEndOf collection: Collection
	) -> Album {
		os_signpost(.begin, log: createLog, name: "Make an Album at the bottom")
		defer {
			os_signpost(.end, log: createLog, name: "Make an Album at the bottom")
		}
		
		let newAlbum = Album(context: managedObjectContext)
		newAlbum.albumPersistentID = Int64(bitPattern: newMediaItem.albumPersistentID)
		newAlbum.index = Int64(collection.contents?.count ?? 0)
		newAlbum.container = collection
		return newAlbum
	}
	
	// Use newAlbumMade(for:atEndOf:) if possible. It's faster.
	private func newAlbumMade(
		for newMediaItem: MPMediaItem,
		atBeginningOf collection: Collection
	) -> Album {
		os_signpost(.begin, log: createLog, name: "Make an Album at the top")
		defer {
			os_signpost(.end, log: createLog, name: "Make an Album at the top")
		}
		
		let existingAlbums = collection.albums(sorted: false)
		existingAlbums.forEach { $0.index += 1 }
		
		let newAlbum = Album(context: managedObjectContext)
		newAlbum.albumPersistentID = Int64(bitPattern: newMediaItem.albumPersistentID)
		newAlbum.index = 0
		newAlbum.container = collection
		return newAlbum
	}
	
	private func newCollectionMade(
		for newMediaItem: MPMediaItem,
		afterAllExistingCollectionsCount numberOfExistingCollections: Int
	) -> Collection {
		os_signpost(.begin, log: createLog, name: "Make a Collection at the bottom")
		defer {
			os_signpost(.end, log: createLog, name: "Make a Collection at the bottom")
		}
		
		let newCollection = Collection(context: managedObjectContext)
		newCollection.title = newMediaItem.albumArtist ?? Album.placeholderAlbumArtist
		newCollection.index = Int64(numberOfExistingCollections)
		return newCollection
	}
	
	// Use newCollectionMade(for:afterAllExistingCollectionsCount:) if possible. It's faster.
	private func newCollectionMade(
		for newMediaItem: MPMediaItem,
		above collectionsToInsertAbove: [Collection]
	) -> Collection {
		os_signpost(.begin, log: createLog, name: "Make a Collection at the top")
		defer {
			os_signpost(.end, log: createLog, name: "Make a Collection at the top")
		}
		
		collectionsToInsertAbove.forEach { $0.index += 1 }
		
		let newCollection = Collection(context: managedObjectContext)
		newCollection.title = newMediaItem.albumArtist ?? Album.placeholderAlbumArtist
		newCollection.index = 0
		return newCollection
	}
	
}
