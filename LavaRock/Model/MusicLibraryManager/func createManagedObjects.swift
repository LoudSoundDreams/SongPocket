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
	
	private static let logForCreateObjects = OSLog(
		subsystem: subsystemName,
		category: "2. Create Managed Objects")
	
	// Make new managed objects for the new media items, including new Albums and Collections to put them in if necessary.
	final func createManagedObjects(
		for newMediaItemsImmutable: [MPMediaItem],
		existingAlbums: [Album],
		existingCollections: [Collection]
	) {
		os_signpost(
			.begin,
			log: Self.logForImportChanges,
			name: "2. Create Managed Objects")
		defer {
			os_signpost(
				.end,
				log: Self.logForImportChanges,
				name: "2. Create Managed Objects")
		}
		
		let shouldImportIntoDefaultOrder = existingCollections.isEmpty
		
		
		// Group the MPMediaItems into albums, sorted by the order we want them in in the app.
//		os_signpost(
//			.begin,
//			log: Self.logForCreateObjects,
//			name: "Initial group and sort")
//		let mediaItemGroups: [[MPMediaItem]]
//		if shouldImportIntoDefaultOrder {
//			let groups = groupedByAlbum(newMediaItemsImmutable)
//			mediaItemGroups = sortedByAlbumArtistNameThenAlbumTitle(mediaItemsGroupedByAlbum: groups)
//		} else {
//			let sortedMediaItems = newMediaItemsImmutable.sorted {
//				$0.dateAdded > $1.dateAdded
//			}
//			mediaItemGroups = groupedByAlbum(sortedMediaItems)
//		}
//		os_signpost(
//			.end,
//			log: Self.logForCreateObjects,
//			name: "Initial group and sort")
		
		
		// Sort the MPMediaItems into the order we want them to appear in in the app.
		os_signpost(
			.begin,
			log: Self.logForCreateObjects,
			name: "Initial sort")
		var sortedMediaItems = [MPMediaItem]()
		if shouldImportIntoDefaultOrder {
			sortedMediaItems = sortedByAlbumArtistNameThenAlbumTitle(newMediaItemsImmutable)
		} else {
			sortedMediaItems = newMediaItemsImmutable.sorted {
				$0.dateAdded > $1.dateAdded
			}
		}
		os_signpost(
			.end,
			log: Self.logForCreateObjects,
			name: "Initial sort")
		// We'll sort Songs within each Album later, because it depends on whether the existing Songs in each Album are in album order.
		os_signpost(
			.begin,
			log: Self.logForCreateObjects,
			name: "Group the MPMediaItems by album")
		let mediaItemGroups = groupedByAlbum(sortedMediaItems)
		os_signpost(
			.end,
			log: Self.logForCreateObjects,
			name: "Group the MPMediaItems by album")
		
		
		os_signpost(
			.begin,
			log: Self.logForCreateObjects,
			name: "Create all the Songs and necessary Albums and Collections")
		var existingAlbumsCopy = existingAlbums
		var existingCollectionsCopy = existingCollections
		for mediaItemGroup in mediaItemGroups.reversed() { // Add Albums from bottom to top.
			os_signpost(
				.begin,
				log: Self.logForCreateObjects,
				name: "Create one Song and possibly a new Album and Collection for it")
			
			let (newAlbum, newCollection) = createSongsAndReturnNewContainers(
				for: mediaItemGroup,
				existingAlbums: existingAlbumsCopy,
				existingCollections: existingCollectionsCopy,
				shouldImportIntoDefaultOrder: shouldImportIntoDefaultOrder)
			
			if let newAlbum = newAlbum {
				existingAlbumsCopy.insert(newAlbum, at: 0)
			}
			if let newCollection = newCollection {
				existingCollectionsCopy.insert(newCollection, at: 0)
			}
			
			os_signpost(
					.end,
					log: Self.logForCreateObjects,
					name: "Create one Song and possibly a new Album and Collection for it")
		}
		os_signpost(
					.end,
					log: Self.logForCreateObjects,
					name: "Create all the Songs and necessary Albums and Collections")
	}
	
	// MARK: - Sorting MPMediaItems
	
	// 1. Group by album artists, sorted alphabetically.
	// - "Unknown Album Artist" should go at the end.
	// 2. Within each album artist, group by albums, sorted by most recent first.
	
	/*
	private func sortedByAlbumArtistNameThenAlbumTitle(
		mediaItemsGroupedByAlbum mediaItemGroups: [[MPMediaItem]]
	) -> [[MPMediaItem]] {
		var mediaItemGroups = mediaItemGroups
		
		os_signpost(
			.begin,
			log: Self.logForCreateObjects,
			name: "Sort by album title")
		mediaItemGroups.sort { // Albums in alphabetical order is wrong! We'll sort Albums by their release dates, but we'll do it later, because we have to keep songs grouped together by album, and some "Album B" could have songs on it that were originally released both before and after the day some earlier "Album A" was released as an album.
			// Don't sort by <. It puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
			let albumTitle0 = $0.first?.albumTitle ?? ""
			let albumTitle1 = $1.first?.albumTitle ?? ""
			return albumTitle0.precedesInAlphabeticalOrderFinderStyle(albumTitle1)
		}
		os_signpost(
			.end,
			log: Self.logForCreateObjects,
			name: "Sort by album title")
		
		os_signpost(
			.begin,
			log: Self.logForCreateObjects,
			name: "Sort by album artist name")
		mediaItemGroups.sort {
			let albumArtist0 = $0.first?.albumArtist ?? ""
			let albumArtist1 = $1.first?.albumArtist ?? ""
			return albumArtist0.precedesInAlphabeticalOrderFinderStyle(albumArtist1)
		}
		os_signpost(
			.end,
			log: Self.logForCreateObjects,
			name: "Sort by album artist name")
		
		os_signpost(
			.begin,
			log: Self.logForCreateObjects,
			name: "Move unknown album artist to end")
		let placeholder = Album.unknownAlbumArtistPlaceholder
		mediaItemGroups.sort { $1.first?.albumArtist ?? placeholder == placeholder }
		os_signpost(
			.end,
			log: Self.logForCreateObjects,
			name: "Move unknown album artist to end")
		
		return mediaItemGroups
	}
	*/
	
	private func sortedByAlbumArtistNameThenAlbumTitle(
		_ mediaItemsImmutable: [MPMediaItem]
	) -> [MPMediaItem] {
		var mediaItemsCopy = mediaItemsImmutable
		
		os_signpost(
			.begin,
			log: Self.logForCreateObjects,
			name: "Sort by album title")
		mediaItemsCopy.sort { // Albums in alphabetical order is wrong! We'll sort Albums by their release dates, but we'll do it later, because we have to keep songs grouped together by album, and some "Album B" could have songs on it that were originally released both before and after the day some earlier "Album A" was released as an album.
			// Don't sort by <. It puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
			let albumTitle0 = $0.albumTitle ?? ""
			let albumTitle1 = $1.albumTitle ?? ""
			return albumTitle0.precedesInAlphabeticalOrderFinderStyle(albumTitle1)
		}
		os_signpost(
			.end,
			log: Self.logForCreateObjects,
			name: "Sort by album title")
		
		os_signpost(
			.begin,
			log: Self.logForCreateObjects,
			name: "Sort by album artist name")
		mediaItemsCopy.sort {
			let albumArtist0 = $0.albumArtist ?? ""
			let albumArtist1 = $1.albumArtist ?? ""
			return albumArtist0.precedesInAlphabeticalOrderFinderStyle(albumArtist1)
		}
		os_signpost(
			.end,
			log: Self.logForCreateObjects,
			name: "Sort by album artist name")
		
		os_signpost(
			.begin,
			log: Self.logForCreateObjects,
			name: "Move unknown album artist to end")
		let placeholder = Album.unknownAlbumArtistPlaceholder
		mediaItemsCopy.sort { $1.albumArtist ?? placeholder == placeholder }
		os_signpost(
			.end,
			log: Self.logForCreateObjects,
			name: "Move unknown album artist to end")
		
		return mediaItemsCopy
	}
	
	// MARK: Grouping MPMediaItems
	
	private func groupedByAlbum(_ sortedMediaItems: [MPMediaItem]) -> [[MPMediaItem]] {
		var groups = [[MPMediaItem]]()
		var seenAlbumPersistentIDs = [MPMediaEntityPersistentID]()
		for mediaItem in sortedMediaItems {
			os_signpost(
				.begin,
				log: Self.logForCreateObjects,
				name: "Find or make an array for one MPMediaItem")
			let thisAlbumPersistentID = mediaItem.albumPersistentID
			if let indexOfMatchingExistingGroup = seenAlbumPersistentIDs.lastIndex(where: { seenAlbumPersistentID in // lastIndex(where:) is around 1.5× as fast as firstIndex(where:) here for first imports
				seenAlbumPersistentID == thisAlbumPersistentID
				// The above is around 5× as fast as:
//			if let indexOfMatchingExistingGroup = groups.lastIndex(where: { existingGroup in
//				existingGroup.first?.albumPersistentID == thisAlbumPersistentID
			}) { // If we've already made a group for this media item.
				groups[indexOfMatchingExistingGroup].append(mediaItem)
				os_signpost(
					.end,
					log: Self.logForCreateObjects,
					name: "Find or make an array for one MPMediaItem")
			} else { // We haven't already made a group for this media item.
				let newGroup = [mediaItem]
				groups.append(newGroup)
				seenAlbumPersistentIDs.append(thisAlbumPersistentID)
				os_signpost(
					.end,
					log: Self.logForCreateObjects,
					name: "Find or make an array for one MPMediaItem")
			}
		}
		return groups
	}
	
	// MARK: - Creating Groups of Songs
	
	private func createSongsAndReturnNewContainers(
		for newMediaItemsInTheSameAlbum: [MPMediaItem],
		existingAlbums: [Album],
		existingCollections: [Collection],
		shouldImportIntoDefaultOrder: Bool
	) -> (Album?, Collection?) {
		guard let firstMediaItemInAlbum = newMediaItemsInTheSameAlbum.first else {
			fatalError("Tried to create Songs (and possibly a new Album and Collection) for a group of MPMediaItems with the same albumPersistentID, but apparently the group was empty.")
		}
		let albumPersistentID_asInt64 = Int64(bitPattern: firstMediaItemInAlbum.albumPersistentID)
		
//		print("")
//		print("Creating Songs and possibly a new Album and Collection for these MPMediaItems:")
//		for newMediaItem in newMediaItemsInTheSameAlbum {
//			print(newMediaItem.title ?? "")
//		}
//		print("The first MPMediaItem has the albumPersistentID: \(albumPersistentID)")
		
		// If we already have a matching Album to add the Songs to …
		if let matchingExistingAlbum = existingAlbums.first(where: { existingAlbum in
			existingAlbum.albumPersistentID == albumPersistentID_asInt64
		}) { // … then add the Songs to that Album.
			if areSongsInAlbumOrder(in: matchingExistingAlbum) {
				createSongs(
					for: newMediaItemsInTheSameAlbum,
					atBeginningOf: matchingExistingAlbum)
				sortSongsByAlbumOrder(in: matchingExistingAlbum)
				
			} else {
				createSongs(
					for: newMediaItemsInTheSameAlbum,
					atBeginningOf: matchingExistingAlbum)
			}
			
			return (nil, nil)
			
		} else { // Otherwise, make the Album to add the Songs to …
			let newContainers = newContainersMade(
				for: firstMediaItemInAlbum,
				existingCollections: existingCollections,
				shouldImportIntoDefaultOrder: shouldImportIntoDefaultOrder)
			let newAlbum = newContainers.0
			
			// … and then add the Songs to that Album.
			let newMediaItemsInAlbumOrder =
				sortedByAlbumOrder(mediaItems: newMediaItemsInTheSameAlbum)
			createSongs(
				for: newMediaItemsInAlbumOrder,
				atBeginningOf: newAlbum)
			
			return newContainers
		}
	}
	
	private func createSongs(
		for newMediaItems: [MPMediaItem],
		atBeginningOf album: Album
	) {
		for mediaItem in newMediaItems.reversed() { // Add songs within each album from bottom to top.
			createSong(
				for: mediaItem,
				atBeginningOf: album)
		}
	}
	
	// MARK: - Sorting MPMediaItems
	
	private func sortedByAlbumOrder(
		mediaItems mediaItemsImmutable: [MPMediaItem]
	) -> [MPMediaItem] {
		var mediaItemsCopy = mediaItemsImmutable
		mediaItemsCopy.sort {
			// Don't sort by <. It puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
			let title0 = $0.title ?? ""
			let title1 = $1.title ?? ""
			return title0.precedesInAlphabeticalOrderFinderStyle(title1)
		}
		mediaItemsCopy.sort { $0.albumTrackNumber < $1.albumTrackNumber }
		mediaItemsCopy.sort { $1.albumTrackNumber == 0 }
		mediaItemsCopy.sort { $0.discNumber < $1.discNumber } // As of iOS 14.0 beta 5, MediaPlayer reports unknown disc numbers as 1, so there's no need to move disc 0 to the end.
		return mediaItemsCopy
	}
	
	// MARK: Checking Order of Saved Songs
	
	private func areSongsInAlbumOrder(in album: Album) -> Bool {
		let songsInAlbum = album.songs()
		
		let mediaItemsInAlbum = songsInAlbum.compactMap { song in // mpMediaItem() returns nil if the media item is no longer in the Music library. Don't let Songs that we'll delete later disrupt an otherwise in-order Album; just skip over them.
			song.mpMediaItem()
		}
		let mediaItemsInAlbumSorted = sortedByAlbumOrder(
			mediaItems: mediaItemsInAlbum)
		
		return mediaItemsInAlbum == mediaItemsInAlbumSorted
	}
	
	// MARK: - Sorting Saved Songs
	
	private func sortSongsByAlbumOrder(in album: Album) {
		let songs = album.songs(sorted: false)
		
		func sortedByAlbumOrder(
			songs songsImmutable: [Song]
		) -> [Song] {
			os_signpost(
				.begin,
				log: Self.logForCreateObjects,
				name: "Sort songs by album order in matching existing Album")
			defer {
				os_signpost(
					.end,
					log: Self.logForCreateObjects,
					name: "Sort songs by album order in matching existing Album")
			}
			
			var songsAndMediaItems = songsImmutable.map { song in
				(song, song.mpMediaItem())
				// mpMediaItem() returns nil if the media item is no longer in the Music library. It doesn't matter where those Songs end up in the array, because we'll delete them later anyway.
			}
			songsAndMediaItems.sort { leftPair, rightPair in
				guard
					let leftMediaItem = leftPair.1,
					let rightMediaItem = rightPair.1
				else {
					return true
				}
				let leftTitle = leftMediaItem.title ?? ""
				let rightTitle = rightMediaItem.title ?? ""
				// Don't sort by <. It puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
				return leftTitle.precedesInAlphabeticalOrderFinderStyle(rightTitle)
			}
			songsAndMediaItems.sort { leftPair, rightPair in
				guard
					let leftMediaItem = leftPair.1,
					let rightMediaItem = rightPair.1
				else {
					return true
				}
				return leftMediaItem.albumTrackNumber < rightMediaItem.albumTrackNumber
			}
			songsAndMediaItems.sort { _, rightPair in
				guard let rightMediaItem = rightPair.1 else {
					return true
				}
				return rightMediaItem.albumTrackNumber == 0
			}
			songsAndMediaItems.sort { leftPair, rightPair in
				guard
					let leftMediaItem = leftPair.1,
					let rightMediaItem = rightPair.1
				else {
					return true
				}
				return leftMediaItem.discNumber < rightMediaItem.discNumber
			}
			return songsAndMediaItems.map { pair in
				pair.0
			}
		}
		
		var sortedSongsInAlbum = sortedByAlbumOrder(songs: songs)
		
		sortedSongsInAlbum.reindex()
	}
	
	// MARK: - Creating Individual Songs
	
	private func createSong(
		for newMediaItem: MPMediaItem,
		atBeginningOf album: Album
	) {
		let existingSongsInAlbum = album.songs(sorted: false)
		for existingSong in existingSongsInAlbum {
			existingSong.index += 1
		}
		
		let newSong = Song(context: managedObjectContext)
		newSong.index = 0
		newSong.persistentID = Int64(bitPattern: newMediaItem.persistentID)
		newSong.container = album
	}
	
	// MARK: - Creating Containers
	
	private func newContainersMade(
		for newMediaItem: MPMediaItem,
		existingCollections: [Collection],
		shouldImportIntoDefaultOrder: Bool
	) -> (Album, Collection?) {
		// If we already have a matching Collection to add the Album to …
		if let matchingExistingCollection = existingCollections.first(where: { existingCollection in
			existingCollection.title == newMediaItem.albumArtist ?? Album.unknownAlbumArtistPlaceholder
		}) { // … then add the Album to that Collection.
			let newAlbum = newAlbumMade(
				for: newMediaItem,
				atBeginningOf: matchingExistingCollection)
			return (newAlbum, nil)
			
		} else { // Otherwise, make the Collection to add the Album to …
			let newCollection = newCollectionMade(
				for: newMediaItem,
				existingCollections: existingCollections,
				shouldImportIntoDefaultOrder: shouldImportIntoDefaultOrder)
			
			// … and then add the Album to that Collection.
			let newAlbum = newAlbumMade(
				for: newMediaItem,
				atBeginningOf: newCollection)
			
			return (newAlbum, newCollection)
		}
	}
	
	private func newAlbumMade(
		for newMediaItem: MPMediaItem,
		atBeginningOf collection: Collection
	) -> Album {
		let existingAlbumsInCollection = collection.albums(sorted: false)
		for existingAlbum in existingAlbumsInCollection {
			existingAlbum.index += 1
		}
		
		let newAlbum = Album(context: managedObjectContext)
		newAlbum.albumPersistentID = Int64(bitPattern: newMediaItem.albumPersistentID)
		newAlbum.index = 0
		newAlbum.container = collection
		
		return newAlbum
	}
	
	private func newCollectionMade(
		for newMediaItem: MPMediaItem,
		existingCollections: [Collection],
		shouldImportIntoDefaultOrder: Bool
	) -> Collection {
		let newCollection = Collection(context: managedObjectContext)
		
		if let titleFromAlbumArtist = newMediaItem.albumArtist {
			newCollection.title = titleFromAlbumArtist
		} else {
			newCollection.title = Album.unknownAlbumArtistPlaceholder
		}
		
		if
			shouldImportIntoDefaultOrder,
			newCollection.title == Album.unknownAlbumArtistPlaceholder
		{
			newCollection.index = Int64(existingCollections.count)
		} else {
			for existingCollection in existingCollections {
				existingCollection.index += 1
			}
			newCollection.index = 0
		}
		
		return newCollection
	}
	
}
