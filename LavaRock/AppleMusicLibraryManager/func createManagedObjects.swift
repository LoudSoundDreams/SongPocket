//
//  func createManagedObjects.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import MediaPlayer

extension AppleMusicLibraryManager {
	
	// Make new managed objects for the new media items, including new Albums and Collections to put them in if necessary.
	final func createManagedObjects(
		for newMediaItemsImmutable: [MPMediaItem],
		existingAlbumsBeforeImport: [Album],
		existingCollectionsBeforeImport: [Collection]
	) {
		let shouldImportIntoDefaultOrder = existingCollectionsBeforeImport.count == 0
		
		var sortedMediaItems = [MPMediaItem]()
		if shouldImportIntoDefaultOrder {
			sortedMediaItems = sortedByAlbumArtistThenAlbum(newMediaItemsImmutable)
		} else {
			sortedMediaItems = newMediaItemsImmutable.sorted() {
				$0.dateAdded > $1.dateAdded
			}
		}
		// We'll sort songs within each album later, because it depends on whether the existing songs in each album are in album order.
		let mediaItemGroups = groupedByAlbum(sortedMediaItems)
		
		var existingAlbumsCopy = existingAlbumsBeforeImport
		var existingCollectionsCopy = existingCollectionsBeforeImport
		for mediaItemGroup in mediaItemGroups.reversed() { // Add albums from bottom to top.
			let (newAlbum, newCollection) = createSongsAndReturnNewContainers(
				for: mediaItemGroup,
				existingAlbums: existingAlbumsCopy,
				existingCollections: existingCollectionsCopy,
				shouldImportIntoDefaultOrder: shouldImportIntoDefaultOrder)
			
			if let newAlbum = newAlbum {
				existingAlbumsCopy.insert(newAlbum, at: 0)
			}
			if let newCollection = newCollection {
				existingCollectionsCopy.insert(newCollection, at: 0) //
			}
		}
	}
	
	// MARK: - Sorting MPMediaItems
	
	private func sortedByAlbumArtistThenAlbum(
		_ mediaItemsImmutable: [MPMediaItem]
	) -> [MPMediaItem] {
		var mediaItemsCopy = mediaItemsImmutable
		mediaItemsCopy.sort() { $0.albumTitle ?? "" < $1.albumTitle ?? "" } // Albums in alphabetical order is wrong! We'll sort albums by their release dates, but we'll do it later, because we have to keep songs grouped together by album, and some "Album B" could have songs on it that were originally released both before and after the day some earlier "Album A" was released as an album.
		mediaItemsCopy.sort() { $0.albumArtist ?? "" < $1.albumArtist ?? "" }
		let unknownAlbumArtistPlaceholder = Album.unknownAlbumArtistPlaceholder()
		mediaItemsCopy.sort() { $1.albumArtist ?? unknownAlbumArtistPlaceholder == unknownAlbumArtistPlaceholder }
		return mediaItemsCopy
	}
	
	// MARK: Grouping MPMediaItems
	
	private func groupedByAlbum(_ mediaItems: [MPMediaItem]) -> [[MPMediaItem]] {
		var groups = [[MPMediaItem]]()
		for mediaItem in mediaItems {
			if let indexOfMatchingExistingGroup = groups.firstIndex(where: { existingGroup in
				existingGroup.first?.albumPersistentID == mediaItem.albumPersistentID
			}) { // If we've already made a group for this media item.
				groups[indexOfMatchingExistingGroup].append(mediaItem)
			} else { // We haven't already made a group for this media item.
				let newGroup = [mediaItem]
				groups.append(newGroup)
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
			fatalError("Tried to add a new group of songs in the same album, but apparently the group was empty.")
		}
		let albumPersistentID = firstMediaItemInAlbum.albumPersistentID
		
		// If we already have a matching Album to add the Songs to …
		if let matchingExistingAlbum = existingAlbums.first(where: { existingAlbum in
			existingAlbum.albumPersistentID == Int64(bitPattern: albumPersistentID)
		}) { // … then add the Songs to that Album.
			if areSongsInAlbumOrder(in: matchingExistingAlbum) {
				createSongs(
					for: newMediaItemsInTheSameAlbum,
					atBeginningOf: matchingExistingAlbum)
				sortSongsByValidAlbumOrder(in: matchingExistingAlbum)
				
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
				sortedByDeterministicAlbumOrder(mediaItems: newMediaItemsInTheSameAlbum)
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
	
	// MARK: - Checking Order of Saved Songs
	
	private func areSongsInAlbumOrder(in album: Album) -> Bool {
//		var songsInAlbum = [Song]()
//		if let contents = album.contents {
//			for element in contents {
//				let songInAlbum = element as! Song
//				print(songInAlbum.titleFormattedOrPlaceholder())
//				songsInAlbum.append(songInAlbum)
//			}
//		}
//		songsInAlbum.sort() { $0.index < $1.index }
		
		let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
		songsFetchRequest.predicate = NSPredicate(format: "container == %@", album)
		songsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		let songsInAlbum = managedObjectContext.objectsFetched(for: songsFetchRequest) as! [Song]
		
		func areInAlbumOrder(songs: [Song]) -> Bool {
			guard songs.count >= 2 else {
				return true
			}
			var discNumberToMatch = 0
			var trackNumberToMatch = 0 //
			for song in songs {
				guard let mediaItem = song.mpMediaItem() else { continue } // The media item might have been deleted. If so, just skip over it; don't let a deleted song disrupt an otherwise in-order album.
				let challengerDiscNumber = mediaItem.discNumber
				let challengerTrackNumber = mediaItem.albumTrackNumber
				if challengerDiscNumber < discNumberToMatch {
					return false
				}
				if challengerDiscNumber == discNumberToMatch {
					if challengerTrackNumber < trackNumberToMatch {
						return false
					}
					if challengerTrackNumber > trackNumberToMatch {
						trackNumberToMatch = challengerTrackNumber
						continue
					}
				}
				if challengerDiscNumber > discNumberToMatch {
					discNumberToMatch = challengerDiscNumber
					trackNumberToMatch = challengerTrackNumber
					continue
				}
			}
			return true
		}
		
		return areInAlbumOrder(songs: songsInAlbum)
	}
	
	// MARK: Sorting Saved Songs
	
	private func sortSongsByValidAlbumOrder(in album: Album) {
		let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
		songsFetchRequest.predicate = NSPredicate(format: "container == %@", album)
		songsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		let songsInAlbum = managedObjectContext.objectsFetched(for: songsFetchRequest) as! [Song]
		
		func sortedByValidAlbumOrder(songs songsImmutable: [Song]) -> [Song] {
			var songsCopy = songsImmutable
			// .mpMediaItem() might return nil, because the media item might have been deleted from the Apple Music library. The default values don't really matter, because we'll delete those songs later anyway.
			songsCopy.sort() { $0.mpMediaItem()?.albumTrackNumber ?? 0 < $1.mpMediaItem()?.albumTrackNumber ?? 0 }
			songsCopy.sort() { $1.mpMediaItem()?.albumTrackNumber ?? 0 == 0 }
			songsCopy.sort() { $0.mpMediaItem()?.discNumber ?? 1 < $1.mpMediaItem()?.discNumber ?? 1 }
			return songsCopy
		}
		
		let sortedSongsInAlbum = sortedByValidAlbumOrder(songs: songsInAlbum)
		
		for index in 0 ..< sortedSongsInAlbum.count {
			let song = sortedSongsInAlbum[index]
			song.index = Int64(index)
		}
	}
	
	// MARK: - Sorting MPMediaItems
	
	private func sortedByDeterministicAlbumOrder(
		mediaItems mediaItemsImmutable: [MPMediaItem]
	) -> [MPMediaItem] {
		var mediaItemsCopy = mediaItemsImmutable
		mediaItemsCopy.sort() { $0.title ?? "" < $1.title ?? "" }
		mediaItemsCopy.sort() { $0.albumTrackNumber < $1.albumTrackNumber }
		mediaItemsCopy.sort() { $1.albumTrackNumber == 0 }
		mediaItemsCopy.sort() { $0.discNumber < $1.discNumber } // As of iOS 14.0 beta 5, MediaPlayer reports unknown disc numbers as 1, so there's no need to move disc 0 to the end.
		return mediaItemsCopy
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
			existingCollection.title == newMediaItem.albumArtist ?? Album.unknownAlbumArtistPlaceholder()
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
			newCollection.title = Album.unknownAlbumArtistPlaceholder()
		}
		
		if
			shouldImportIntoDefaultOrder,
			newCollection.title == Album.unknownAlbumArtistPlaceholder()
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
