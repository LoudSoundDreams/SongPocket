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
		
		// Group the MPMediaItems into albums, sorted by the order we want them in in the app.
		let mediaItemGroups: [[MPMediaItem]] = {
			if shouldImportIntoDefaultOrder {
				let dictionary = groupedByAlbumPersistentID(Array(newMediaItems))
				let groups = dictionary.map { $0.value }
				os_signpost(.begin, log: createLog, name: "Initial Sort")
				let sortedGroups = sortedByAlbumArtistNameThenAlbumTitle(mediaItemGroups: groups)
				// We'll sort Albums by release date later.
				os_signpost(.end, log: createLog, name: "Initial Sort")
				return sortedGroups
			} else {
				os_signpost(.begin, log: createLog, name: "Initial Sort")
				let sortedMediaItems = newMediaItems.sorted { $0.dateAdded > $1.dateAdded }
				os_signpost(.end, log: createLog, name: "Initial Sort")
				let dictionary = groupedByAlbumPersistentID(sortedMediaItems)
				let groups = dictionary.map { $0.value }
				return groups
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
		
		os_signpost(.begin, log: createLog, name: "Create all the Songs and necessary Albums and Collections")
		
		
		let mediaItemGroupsCopy: [[MPMediaItem]] = {
			if shouldImportIntoDefaultOrder {
				return mediaItemGroups
			} else {
				return mediaItemGroups.reversed()
			}
		}()
		
		
		mediaItemGroupsCopy.forEach { mediaItemGroup in // Fix this
//		mediaItemGroups.forEach { mediaItemGroup in
			os_signpost(.begin, log: createLog, name: "Create one group of Songs and possibly new containers")
			let (newAlbum, newCollection) = createSongsAndReturnNewContainers(
				for: mediaItemGroup,
				   existingAlbums: existingAlbumsByAlbumPersistentID,
				   existingCollections: existingCollectionsByTitle,
				   shouldImportIntoDefaultOrder: shouldImportIntoDefaultOrder)
			
			if let newAlbum = newAlbum {
				let albumPersistentID_asUInt64
				= MPMediaEntityPersistentID(bitPattern: newAlbum.albumPersistentID)
				existingAlbumsByAlbumPersistentID[albumPersistentID_asUInt64] = newAlbum
			}
			if let newCollection = newCollection {
				existingCollectionsByTitle[newCollection.title!] = newCollection
			}
			os_signpost(.end, log: createLog, name: "Create one group of Songs and possibly new containers")
		}
		os_signpost(.end, log: createLog, name: "Create all the Songs and necessary Albums and Collections")
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
		// Verified as of build 154 on iOS 14.7 beta 5.
		let sortedMediaItemGroups = mediaItemGroups.sorted {
			// Don't sort Strings by <. That puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
			
			let leftAlbumArtist = $0.first?.albumArtist
			let rightAlbumArtist = $1.first?.albumArtist
			// Either can be nil
			
			guard leftAlbumArtist != rightAlbumArtist else {
				// Sort by album title
				let leftAlbumTitle = $0.first?.albumTitle ?? ""
				let rightAlbumTitle = $1.first?.albumTitle ?? ""
				return leftAlbumTitle.precedesAlphabeticallyFinderStyle(rightAlbumTitle)
			}
			
			// Move unknown album artist to end
			guard let rightAlbumArtist = $1.first?.albumArtist else {
				return true
			}
			guard let leftAlbumArtist = $0.first?.albumArtist else {
				return false
			}
			
			// Sort by album artist
			return leftAlbumArtist.precedesAlphabeticallyFinderStyle(rightAlbumArtist)
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
		guard let firstMediaItemInAlbum = mediaItemGroup.first else {
			fatalError("Tried to create Songs (and possibly a new Album and Collection) for a group of MPMediaItems with the same albumPersistentID, but apparently the group was empty.")
		}
		// If we already have a matching Album to add the Songs to …
		if let matchingExistingAlbum = existingAlbums[firstMediaItemInAlbum.albumPersistentID] {
			// … then add the Songs to that Album.
			
			if areSongsInAlbumDisplayOrder(in: matchingExistingAlbum) {
				createSongs(
					for: mediaItemGroup,
					atBeginningOf: matchingExistingAlbum)
				os_signpost(.begin, log: createLog, name: "Put the existing Album back in order")
				let songsInAlbum = matchingExistingAlbum.songs(sorted: false)
				sortByAlbumDisplayOrder(songs: songsInAlbum)
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
			let newContainers = newContainersMade(
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
		os_signpost(.begin, log: createLog, name: "Make new Songs at the end of an Album")
		defer {
			os_signpost(.end, log: createLog, name: "Make new Songs at the end of an Album")
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
		os_signpost(.begin, log: createLog, name: "Make new Songs at the beginning of an Album")
		defer {
			os_signpost(.end, log: createLog, name: "Make new Songs at the beginning of an Album")
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
		return mediaItems.sorted { $0.precedesInSameAlbumInDisplayOrder($1) }
	}
	
	// MARK: - Sorting Saved Songs
	
	private func areSongsInAlbumDisplayOrder(in album: Album) -> Bool {
		let songs = album.songs()
		let mediaItems = songs.compactMap { $0.mpMediaItem() }
		// mpMediaItem() returns nil if the media item is no longer in the Music library. Don't let Songs that we'll delete later disrupt an otherwise in-order Album; just skip over them.
		
		let sortedMediaItems = sortedByAlbumDisplayOrder(mediaItems: mediaItems)
		
		return mediaItems == sortedMediaItems
	}
	
	private func sortByAlbumDisplayOrder(songs: [Song]) {
		
		func sortedByAlbumDisplayOrder(songs: [Song]) -> [Song] {
			var songsAndMediaItems = songs.map {
				($0,
				 $0.mpMediaItem())
				// mpMediaItem() returns nil if the media item is no longer in the Music library. It doesn't matter where those Songs end up in the array, because we'll delete them later anyway.
			}
			
			songsAndMediaItems.sort { leftTuple, rightTuple in
				guard
					let leftMediaItem = leftTuple.1,
					let rightMediaItem = rightTuple.1
				else {
					return true
				}
				return leftMediaItem.precedesInSameAlbumInDisplayOrder(rightMediaItem)
			}
			
			let result = songsAndMediaItems.map { tuple in tuple.0 }
			return result
		}
		
		var sortedSongs = sortedByAlbumDisplayOrder(songs: songs)
		
		sortedSongs.reindex()
	}
	
	// MARK: - Creating Containers
	
	private func newContainersMade(
		for newMediaItem: MPMediaItem,
		existingCollections: [String: Collection],
		shouldImportIntoDefaultOrder: Bool
	) -> (album: Album, collection: Collection?) {
		// If we already have a matching Collection to add the Album to …
		let collectionTitleToLookUp
		= newMediaItem.albumArtist ?? Album.unknownAlbumArtistPlaceholder
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
						   afterNumberOfExistingCollections: existingCollections.count)
					
					
				} else {
					return newCollectionMade(
						for: newMediaItem,
						   aboveAllExistingCollections: existingCollections)
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
		os_signpost(.begin, log: createLog, name: "Make a new Album at the bottom of a Collection")
		defer {
			os_signpost(.end, log: createLog, name: "Make a new Album at the bottom of a Collection")
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
		os_signpost(.begin, log: createLog, name: "Make a new Album at the top of a Collection")
		defer {
			os_signpost(.end, log: createLog, name: "Make a new Album at the top of a Collection")
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
		afterNumberOfExistingCollections numberOfExistingCollections: Int
	) -> Collection {
		os_signpost(.begin, log: createLog, name: "Make a new Collection at the bottom")
		defer {
			os_signpost(.end, log: createLog, name: "Make a new Collection at the bottom")
		}
		
		let newCollection = Collection(context: managedObjectContext)
		newCollection.title = newMediaItem.albumArtist ?? Album.unknownAlbumArtistPlaceholder
		newCollection.index = Int64(numberOfExistingCollections)
		return newCollection
	}
	
	// Use newCollectionMade(for:afterNumberOfExistingCollections:) if possible. It's faster.
	private func newCollectionMade(
		for newMediaItem: MPMediaItem,
		aboveAllExistingCollections existingCollectionsByTitle: [String: Collection]
	) -> Collection {
		os_signpost(.begin, log: createLog, name: "Make a new Collection at the top")
		defer {
			os_signpost(.end, log: createLog, name: "Make a new Collection at the top")
		}
		
		let existingCollections = existingCollectionsByTitle.map { $0.value }
		existingCollections.forEach { $0.index += 1 }
		
		let newCollection = Collection(context: managedObjectContext)
		newCollection.title = newMediaItem.albumArtist ?? Album.unknownAlbumArtistPlaceholder
		newCollection.index = 0
		return newCollection
	}
	
}
