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
		for newMediaItems: [MPMediaItem],
		isAppDatabaseEmpty: Bool,
		existingAlbums: [Album],
		existingCollections: [Collection]
	) {
		var sortedMediaItems = [MPMediaItem]()
		if isAppDatabaseEmpty {
			sortedMediaItems = sortedByAlbumArtistThenAlbum(newMediaItems)
		} else {
			sortedMediaItems = newMediaItems.sorted() {
				$0.dateAdded > $1.dateAdded
			}
		}
		// We'll sort songs within each album later, because it depends on whether the existing songs in each album are in album order.
		let mediaItemGroups = groupedByAlbum(sortedMediaItems)
		for mediaItemGroup in mediaItemGroups.reversed() {
			createManagedObjects(
				for: mediaItemGroup,
				existingAlbums: existingAlbums,
				existingCollections: existingCollections)
		}
	}
	
	// MARK: - Sorting MPMediaItems
	
	private func sortedByAlbumArtistThenAlbum(_ mediaItemsImmutable: [MPMediaItem]) -> [MPMediaItem] {
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
	
	private func createManagedObjects(
		for newMediaItemsInTheSameAlbum: [MPMediaItem],
		existingAlbums: [Album],
		existingCollections: [Collection]
	) {
		guard let firstMediaItemInAlbum = newMediaItemsInTheSameAlbum.first else { return }
		let albumPersistentID = firstMediaItemInAlbum.albumPersistentID
		
		// If we already have an Album for these media items, then make Songs for these media items in that Album.
		if let matchingExistingAlbum = existingAlbums.first(where: { existingAlbum in
			existingAlbum.albumPersistentID == Int64(bitPattern: albumPersistentID)
		}) {
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
			
		} else { // Otherwise, we don't already have an Album for these media items, so make that Album and then add the Songs to that Album.
			let newAlbum = createAlbum(for: firstMediaItemInAlbum)
			
			let newMediaItemsInAlbumOrder =
				sortedByDeterministicAlbumOrder(mediaItems: newMediaItemsInTheSameAlbum)
			createSongs(
				for: newMediaItemsInAlbumOrder,
				atBeginningOf: newAlbum)
		}
	}
	
	private func createSongs(
		for newMediaItems: [MPMediaItem],
		atBeginningOf album: Album
	) {
		for mediaItem in newMediaItems.reversed() {
			createSong(
				for: mediaItem,
				atBeginningOfAlbumWith: album.objectID)
		}
	}
	
	// MARK: - Checking Order of Existing Songs
	
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
	
	// MARK: Sorting Existing Songs
	
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
	
	private func createAlbum(for newMediaItem: MPMediaItem) -> Album {
		let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
		// Order matters, because we're going to (try to) add the album to the *first* collection with a matching title.
		collectionsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		let existingCollections = managedObjectContext.objectsFetched(for: collectionsFetchRequest)
		
		// 2.1. If we already have a Collection with a matching title, then add the Album to that Collection.
		if let existingCollectionWithMatchingTitle = existingCollections.first(where: { existingCollection in
			(existingCollection as! Collection).title == newMediaItem.albumArtist ?? Album.unknownAlbumArtistPlaceholder()
		}) {
			let existingCollection = existingCollectionWithMatchingTitle as! Collection
			
			if let existingAlbumsInCollection = existingCollection.contents {
				for existingAlbum in existingAlbumsInCollection {
					(existingAlbum as! Album).index += 1
				}
			}
			
			let newAlbum = Album(context: managedObjectContext)
			newAlbum.albumPersistentID = Int64(bitPattern: newMediaItem.albumPersistentID)
			newAlbum.index = 0
			newAlbum.container = existingCollection
			
			
			return newAlbum
			
			
		} else { // 2.2. Otherwise, make the Collection to add the Album to.
			createCollection(for: newMediaItem)
			// … and then try 2 again (risking an infinite loop).
			return createAlbum(for: newMediaItem)
		}
	}
	
	private func createCollection(for newMediaItem: MPMediaItem) {
		let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
		// Order doesn't matter.
		let existingCollections = managedObjectContext.objectsFetched(for: collectionsFetchRequest) as! [Collection]
		let newCollection = Collection(context: managedObjectContext)
		
		if let defaultTitle = newMediaItem.albumArtist {
			for existingCollection in existingCollections {
				existingCollection.index += 1
			}
			
			newCollection.title = defaultTitle
			newCollection.index = 0
			
		} else {
			newCollection.title = Album.unknownAlbumArtistPlaceholder()
		}
	}
	
}
