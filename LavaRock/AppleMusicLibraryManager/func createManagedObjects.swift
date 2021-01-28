//
//  func createManagedObjects.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import MediaPlayer
import OSLog

extension AppleMusicLibraryManager {
	
	private static let createManagedObjectsLog = OSLog(
		subsystem: subsystemForOSLog,
		category: "2. Create Managed Objects")
	
	// Make new managed objects for the new media items, including new Albums and Collections to put them in if necessary.
	final func createManagedObjects(
		for newMediaItemsImmutable: [MPMediaItem],
		existingAlbums: [Album],
		existingCollections: [Collection]
	) {
		os_signpost(.begin, log: Self.importChangesMainLog, name: "2. Create Managed Objects")
		defer {
			os_signpost(.end, log: Self.importChangesMainLog, name: "2. Create Managed Objects")
		}
		
		let shouldImportIntoDefaultOrder = existingCollections.isEmpty
		
		// Sort the MPMediaItems into the order we want them to appear in in the app.
		os_signpost(.begin, log: Self.createManagedObjectsLog, name: "Initial sort")
		var sortedMediaItems = [MPMediaItem]()
		if shouldImportIntoDefaultOrder {
			sortedMediaItems = sortedByAlbumArtistThenAlbum(newMediaItemsImmutable)
		} else {
			sortedMediaItems = newMediaItemsImmutable.sorted {
				$0.dateAdded > $1.dateAdded
			}
		}
		os_signpost(.end, log: Self.createManagedObjectsLog, name: "Initial sort")
		// We'll sort Songs within each Album later, because it depends on whether the existing Songs in each Album are in album order.
		os_signpost(.begin, log: Self.createManagedObjectsLog, name: "Group the MPMediaItems by album")
		let mediaItemGroups = groupedByAlbum(sortedMediaItems)
		os_signpost(.end, log: Self.createManagedObjectsLog, name: "Group the MPMediaItems by album")
		
		os_signpost(.begin, log: Self.createManagedObjectsLog, name: "Create all the Songs and necessary Albums and Collections")
		var existingAlbumsCopy = existingAlbums
		var existingCollectionsCopy = existingCollections
		for mediaItemGroup in mediaItemGroups.reversed() { // Add Albums from bottom to top.
			os_signpost(.begin, log: Self.createManagedObjectsLog, name: "Create one Song and possibly a new Album and Collection for it")
			
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
			
			os_signpost(.end, log: Self.createManagedObjectsLog, name: "Create one Song and possibly a new Album and Collection for it")
		}
		os_signpost(.end, log: Self.createManagedObjectsLog, name: "Create all the Songs and necessary Albums and Collections")
	}
	
	// MARK: - Sorting MPMediaItems
	
	private func sortedByAlbumArtistThenAlbum(
		_ mediaItemsImmutable: [MPMediaItem]
	) -> [MPMediaItem] {
		var mediaItemsCopy = mediaItemsImmutable
		os_signpost(.begin, log: Self.createManagedObjectsLog, name: "Sort by album title")
		mediaItemsCopy.sort { // Albums in alphabetical order is wrong! We'll sort Albums by their release dates, but we'll do it later, because we have to keep songs grouped together by album, and some "Album B" could have songs on it that were originally released both before and after the day some earlier "Album A" was released as an album.
			// Don't sort by <. It puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
			let albumTitle0 = $0.albumTitle ?? ""
			let albumTitle1 = $1.albumTitle ?? ""
			let comparisonResult = albumTitle0.localizedStandardCompare(albumTitle1) // The comparison method that the Finder uses
			return comparisonResult == .orderedAscending
		}
		os_signpost(.end, log: Self.createManagedObjectsLog, name: "Sort by album title")
		os_signpost(.begin, log: Self.createManagedObjectsLog, name: "Sort by album artist name")
		mediaItemsCopy.sort {
			let albumArtist0 = $0.albumArtist ?? ""
			let albumArtist1 = $1.albumArtist ?? ""
			let comparisonResult = albumArtist0.localizedStandardCompare(albumArtist1)
			return comparisonResult == .orderedAscending
		}
		os_signpost(.end, log: Self.createManagedObjectsLog, name: "Sort by album artist name")
		os_signpost(.begin, log: Self.createManagedObjectsLog, name: "Move unknown album artist to end")
		let placeholder = Album.unknownAlbumArtistPlaceholder
		mediaItemsCopy.sort { $1.albumArtist ?? placeholder == placeholder }
		os_signpost(.end, log: Self.createManagedObjectsLog, name: "Move unknown album artist to end")
		return mediaItemsCopy
	}
	
	// MARK: Grouping MPMediaItems
	
	// Speeds up first import by 1.5x, but slows down subsequent launches (?!) by 2x. (Tested with a release build and 13,142 songs on an iPhone 6s Plus.)
//	private func groupedByAlbum(_ sortedMediaItems: [MPMediaItem]) -> [[MPMediaItem]] {
//		var groups = [[MPMediaItem]]()
//		var seenAlbumPersistentIDs = [MPMediaEntityPersistentID]()
//		for mediaItem in sortedMediaItems {
//			os_signpost(.begin, log: Self.createManagedObjectsLog, name: "Find or make an array for one MPMediaItem")
//			let thisAlbumPersistentID = mediaItem.albumPersistentID
//			if let indexOfMatchingExistingGroup = seenAlbumPersistentIDs.lastIndex(where: { seenAlbumPersistentID in
//				seenAlbumPersistentID == thisAlbumPersistentID
//			}) { // If we've already made a group for this media item.
//				groups[indexOfMatchingExistingGroup].append(mediaItem)
//				os_signpost(.end, log: Self.createManagedObjectsLog, name: "Find or make an array for one MPMediaItem")
//			} else { // We haven't already made a group for this media item.
//				let newGroup = [mediaItem]
//				groups.append(newGroup)
//				seenAlbumPersistentIDs.append(thisAlbumPersistentID)
//				os_signpost(.end, log: Self.createManagedObjectsLog, name: "Find or make an array for one MPMediaItem")
//			}
//		}
//		return groups
//	}
	
	private func groupedByAlbum(_ sortedMediaItems: [MPMediaItem]) -> [[MPMediaItem]] {
		var groups = [[MPMediaItem]]()
		for mediaItem in sortedMediaItems {
			os_signpost(.begin, log: Self.createManagedObjectsLog, name: "Find or make an array for one MPMediaItem")
			if var matchingExistingGroup = groups.last(where: { existingGroup in
				existingGroup.first?.albumPersistentID == mediaItem.albumPersistentID // last(where:) takes around 2/3 as long as first(where:) for first imports
			}) { // If we've already made a group for this media item.
				matchingExistingGroup.append(mediaItem)
				os_signpost(.end, log: Self.createManagedObjectsLog, name: "Find or make an array for one MPMediaItem")
			} else { // We haven't already made a group for this media item.
				let newGroup = [mediaItem]
				groups.append(newGroup)
				os_signpost(.end, log: Self.createManagedObjectsLog, name: "Find or make an array for one MPMediaItem")
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
				atBeginningOfAlbumWith: album.objectID)
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
			let comparisonResult = title0.localizedStandardCompare(title1) // The comparison method that the Finder uses
			return comparisonResult == .orderedAscending
		}
		mediaItemsCopy.sort { $0.albumTrackNumber < $1.albumTrackNumber }
		mediaItemsCopy.sort { $1.albumTrackNumber == 0 }
		mediaItemsCopy.sort { $0.discNumber < $1.discNumber } // As of iOS 14.0 beta 5, MediaPlayer reports unknown disc numbers as 1, so there's no need to move disc 0 to the end.
		return mediaItemsCopy
	}
	
	// MARK: Checking Order of Saved Songs
	
	private func areSongsInAlbumOrder(in album: Album) -> Bool {
		var songs = [Song]()
		if let contents = album.contents {
			for element in contents {
				let songInAlbum = element as! Song
				songs.append(songInAlbum)
			}
		}
		let songsInAlbum = songs.sorted { $0.index < $1.index }
		
		var mediaItemsInAlbum = [MPMediaItem]()
		for songInAlbum in songsInAlbum {
			guard let mediaItemInAlbum = songInAlbum.mpMediaItem() else { continue } // .mpMediaItem() returns nil if the media item is no longer in the Apple Music library. Don't let Songs that we'll delete later disrupt an otherwise in-order Album; just skip over them.
			mediaItemsInAlbum.append(mediaItemInAlbum)
		}
		
		let mediaItemsInAlbumSorted = sortedByAlbumOrder(mediaItems: mediaItemsInAlbum)
		
		return mediaItemsInAlbum == mediaItemsInAlbumSorted
	}
	
	// MARK: - Sorting Saved Songs
	
	private func sortSongsByAlbumOrder(in album: Album) {
		var songs = [Song]()
		if let contents = album.contents {
			for element in contents {
				let songInAlbum = element as! Song
				songs.append(songInAlbum)
			}
		}
		
		func sortedByAlbumOrder(songs songsImmutable: [Song]) -> [Song] {
			var songsCopy = songsImmutable
			// TO DO: Does this match sortedByAlbumOrder(mediaItems:) exactly? You can guarantee it by doing some setup moves and calling sortedByAlbumOrder(mediaItems:) itself.
			// .mpMediaItem() returns nil if the media item is no longer in the Apple Music library. It doesn't matter where those Songs end up in the array, because we'll delete them later anyway.
			songsCopy.sort {
				// Don't sort by <. It puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
				let title0 = $0.titleFormattedOrPlaceholder()
				let title1 = $1.titleFormattedOrPlaceholder()
				let comparisonResult = title0.localizedStandardCompare(title1) // The comparison method that the Finder uses
				return comparisonResult == .orderedAscending
			}
			songsCopy.sort {
				$0.mpMediaItem()?.albumTrackNumber ?? 0 <
					$1.mpMediaItem()?.albumTrackNumber ?? 0
			}
			songsCopy.sort {
				$1.mpMediaItem()?.albumTrackNumber ?? 0 == 0
			}
			songsCopy.sort {
				$0.mpMediaItem()?.discNumber ?? 1 <
					$1.mpMediaItem()?.discNumber ?? 1
			}
			return songsCopy
		}
		
		let sortedSongsInAlbum = sortedByAlbumOrder(songs: songs)
		
		for index in 0 ..< sortedSongsInAlbum.count {
			let song = sortedSongsInAlbum[index]
			song.index = Int64(index)
		}
	}
	
	// MARK: - Creating Individual Songs
	
	private func createSong(
		for newMediaItem: MPMediaItem,
		atBeginningOfAlbumWith albumID: NSManagedObjectID
	) {
		let album = managedObjectContext.object(with: albumID) as! Album
		
		if let existingSongsInAlbum = album.contents {
			for existingSong in existingSongsInAlbum {
				(existingSong as! Song).index += 1
			}
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
		if let existingAlbumsInCollection = collection.contents {
			for existingAlbum in existingAlbumsInCollection {
				(existingAlbum as! Album).index += 1
			}
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
