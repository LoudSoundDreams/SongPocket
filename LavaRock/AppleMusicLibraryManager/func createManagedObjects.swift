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
		existingCollections: [Collection],
		via managedObjectContext: NSManagedObjectContext
	) {
		var sortedMediaItems = [MPMediaItem]()
		if isAppDatabaseEmpty {
			sortedMediaItems = sortedByAlbumArtistThenAlbum(newMediaItems)
		} else {
			sortedMediaItems = sortedByRecentlyAddedFirst(newMediaItems)
		}
		// We'll sort songs within each album later, because it depends on whether the existing songs in each album are in album order.
		let mediaItemGroups = groupedByAlbum(sortedMediaItems)
		for mediaItemGroup in mediaItemGroups.reversed() {
			createManagedObjects(
				for: mediaItemGroup,
				existingAlbums: existingAlbums,
				existingCollections: existingCollections,
				via: managedObjectContext)
		}
		
		
//		let mediaItemsSortedInReverse = sortedInReverseTargetOrder(
//			mediaItems: mediaItems,
//			isAppDatabaseEmpty: isAppDatabaseEmpty)
//
//		for mediaItem in mediaItemsSortedInReverse {
//			createManagedObjects(
//				for: mediaItem,
//				via: managedObjectContext)
//		}
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
	
	private func sortedByRecentlyAddedFirst(_ mediaItemsImmutable: [MPMediaItem]) -> [MPMediaItem] {
		return mediaItemsImmutable.sorted() {
			$0.dateAdded > $1.dateAdded
		}
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
		existingCollections: [Collection],
		via managedObjectContext: NSManagedObjectContext
	) {
		guard let firstMediaItemInAlbum = newMediaItemsInTheSameAlbum.first else { return }
		let albumPersistentID = firstMediaItemInAlbum.albumPersistentID
		
		// If we already have an Album for these media items, then make Songs for these media items in that Album.
		if let matchingExistingAlbum = existingAlbums.first(where: { existingAlbum in
			existingAlbum.albumPersistentID == Int64(bitPattern: albumPersistentID)
		}) {
			if areSongsInAlbumOrder(
				in: matchingExistingAlbum,
				via: managedObjectContext)
			{
				createSongs(
					for: newMediaItemsInTheSameAlbum,
					atBeginningOf: matchingExistingAlbum,
					via: managedObjectContext)
				sortSongsByAlbumOrder(
					in: matchingExistingAlbum,
					via: managedObjectContext)
				
			} else {
				createSongs(
					for: newMediaItemsInTheSameAlbum,
					atBeginningOf: matchingExistingAlbum,
					via: managedObjectContext)
			}
			
		} else { // Otherwise, we don't already have an Album for these media items, so make that Album and then add the Songs to that Album.
			let newAlbum = createAlbum(
				for: firstMediaItemInAlbum,
				via: managedObjectContext)
			
			let newMediaItemsInAlbumOrder =
				sortedByAlbumOrder(mediaItems: newMediaItemsInTheSameAlbum)
			createSongs(
				for: newMediaItemsInAlbumOrder,
				atBeginningOf: newAlbum,
				via: managedObjectContext)
		}
	}
	
	private func createSongs(
		for newMediaItems: [MPMediaItem],
		atBeginningOf album: Album,
		via managedObjectContext: NSManagedObjectContext
	) {
		for mediaItem in newMediaItems.reversed() {
			createSong(
				for: mediaItem,
				atBeginningOfAlbumWith: album.objectID,
				via: managedObjectContext)
		}
	}
	
	// MARK: - Checking Order of Existing Songs
	
	private func areSongsInAlbumOrder(
		in album: Album,
		via managedObjectContext: NSManagedObjectContext
	) -> Bool {
		var result = false // False is a safer default than true, because even if we're wrong, we'll just add new songs to the top, with the most recent at the top; we won't unexpectedly clean up the manual sort order.
		managedObjectContext.performAndWait {
			
//			var songsInAlbum = [Song]()
//			if let contents = album.contents {
//				for element in contents {
//					let songInAlbum = element as! Song
//					print(songInAlbum.titleFormattedOrPlaceholder())
//					songsInAlbum.append(songInAlbum)
//				}
//			}
//			songsInAlbum.sort() { $0.index < $1.index }
			
			let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
			songsFetchRequest.predicate = NSPredicate(format: "container == %@", album)
			songsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
			let songsInAlbum = managedObjectContext.objectsFetched(for: songsFetchRequest) as! [Song]
			
			func areInAlbumOrder(songs: [Song]) -> Bool {
				guard songs.count >= 2 else {
					return true
				}
				var discNumberToMatch = 0
				var trackNumberToMatch = 0
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
			
//			func areInValidOrder(songs: [Song]) -> Bool {
//				guard songs.count >= 2 else {
//					return true
//				}
//				if
//					songs[0].mpMediaItem() == nil
//						||
//
//						songs[0].mpMediaItem()?.discNumber ?? 1 < songs[1].mpMediaItem()?.discNumber ?? 1
//						|| (songs[0].mpMediaItem()?.discNumber ?? 1 == songs[1].mpMediaItem()?.discNumber ?? 1
//								&& songs[0].mpMediaItem()?.albumTrackNumber ?? 0 <= songs[1].mpMediaItem()?.albumTrackNumber ?? 0)
//
//
//				{
//					var songsCopy = songs
//					songsCopy.remove(at: 0)
//					return areInValidOrder(songs: songsCopy)
//				} else {
//					return false
//				}
//			}
			
			result = areInAlbumOrder(songs: songsInAlbum)
		}
		return result
	}
	
	// MARK: Sorting Songs Within Albums
	
	private func sortSongsByAlbumOrder(
		in album: Album,
		via managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
			songsFetchRequest.predicate = NSPredicate(format: "container == %@", album)
			songsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
			let songsInAlbum = managedObjectContext.objectsFetched(for: songsFetchRequest) as! [Song]
			
			let sortedSongsInAlbum =
				sortedByAlbumOrder(
					songs: songsInAlbum,
					via: managedObjectContext)
			
			for index in 0 ..< sortedSongsInAlbum.count {
				let song = sortedSongsInAlbum[index]
				song.index = Int64(index)
			}
		}
	}
	
	private func sortedByAlbumOrder(
		songs songsImmutable: [Song],
		via managedObjectContext: NSManagedObjectContext
	) -> [Song] {
		var songsCopy = songsImmutable
		managedObjectContext.performAndWait {
			// .mpMediaItem() might return nil, because the media item might have been deleted from the Apple Music library. The default values don't really matter, because we'll delete those songs later anyway.
			songsCopy.sort() { $0.mpMediaItem()?.title ?? "" < $1.mpMediaItem()?.title ?? "" }
			songsCopy.sort() { $0.mpMediaItem()?.albumTrackNumber ?? 0 < $1.mpMediaItem()?.albumTrackNumber ?? 0 }
			songsCopy.sort() { $1.mpMediaItem()?.albumTrackNumber ?? 0 == 0 }
			songsCopy.sort() { $0.mpMediaItem()?.discNumber ?? 1 < $1.mpMediaItem()?.discNumber ?? 1 }
		}
		return songsCopy
	}
	
	private func sortedByAlbumOrder(
		mediaItems mediaItemsImmutable: [MPMediaItem]
	) -> [MPMediaItem] {
		var mediaItemsCopy = mediaItemsImmutable
		mediaItemsCopy.sort() { $0.title ?? "" < $1.title ?? "" }
		mediaItemsCopy.sort() { $0.albumTrackNumber < $1.albumTrackNumber }
		mediaItemsCopy.sort() { $1.albumTrackNumber == 0 }
		mediaItemsCopy.sort() { $0.discNumber < $1.discNumber } // As of iOS 14.0 beta 5, MediaPlayer reports unknown disc numbers as 1, so there's no need to move disc 0 to the end.
		return mediaItemsCopy
	}
	
	
	
	/*
	private func sortedInReverseTargetOrder(
	mediaItems mediaItemsImmutable: [MPMediaItem],
	isAppDatabaseEmpty: Bool
	) -> [MPMediaItem] {
	var mediaItems = mediaItemsImmutable
	if isAppDatabaseEmpty {
	mediaItems.sort() { ($0.title ?? "") < ($1.title ?? "") }
	mediaItems.sort() { $0.albumTrackNumber < $1.albumTrackNumber }
	mediaItems.sort() { $1.albumTrackNumber == 0 }
	mediaItems.sort() { $0.discNumber < $1.discNumber } // As of iOS 14.0 beta 5, MediaPlayer reports unknown disc numbers as 1, so there's no need to move disc 0 to the end.
	mediaItems.sort() { ($0.albumTitle ?? "") < ($1.albumTitle ?? "") } // Albums in alphabetical order is wrong! We'll sort albums by their release dates, but we'll do it later, because we have to keep songs grouped together by album, and some "Album B" could have songs on it that were originally released both before and after the day some earlier "Album A" was released as an album.
	mediaItems.sort() { ($0.albumArtist ?? "") < ($1.albumArtist ?? "") }
	let unknownAlbumArtistPlaceholder = Album.unknownAlbumArtistPlaceholder()
	mediaItems.sort() { ($1.albumArtist ?? unknownAlbumArtistPlaceholder) == unknownAlbumArtistPlaceholder }
	} else {
	mediaItems.sort() { ($0.dateAdded) > ($1.dateAdded) }
	}
	mediaItems.reverse()
	
	return mediaItems
	}
	
	private func createManagedObjects(
	for mediaItem: MPMediaItem,
	via managedObjectContext: NSManagedObjectContext
	) {
	managedObjectContext.performAndWait {
	let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
	// Order doesn't matter; we're just trying to get a match.
	let allAlbums = managedObjectContext.objectsFetched(for: albumsFetchRequest) as! [Album]
	
	// 1. If we already have the Album to add the Song to, then add the Song to that Album.
	if let matchingExistingAlbum = allAlbums.first(where: { existingAlbum in
	existingAlbum.albumPersistentID == Int64(bitPattern: mediaItem.albumPersistentID)
	}) {
	createSong(
	for: mediaItem,
	atBeginningOfAlbumWith: matchingExistingAlbum.objectID,
	via: managedObjectContext)
	
	} else { // 2. Otherwise, make the Album to add the Song to.
	let _ = createAlbum(
	for: mediaItem,
	via: managedObjectContext)
	// … and then try 1 again (risking an infinite loop).
	createManagedObjects(
	for: mediaItem,
	via: managedObjectContext)
	}
	}
	}
	*/
	
	// MARK: - Creating Individual Songs
	
	private func createSong(
		for newMediaItem: MPMediaItem,
		atBeginningOfAlbumWith albumID: NSManagedObjectID,
		via managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
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
	}
	
	// MARK: - Creating Containers
	
	private func createAlbum(
		for newMediaItem: MPMediaItem,
		via managedObjectContext: NSManagedObjectContext
	) -> Album {
		// We should only be running this if we don't already have a managed object for the album for the song.
		
		
		var newAlbumToReturn: Album?
		
		
		managedObjectContext.performAndWait {
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
				
				
				newAlbumToReturn = newAlbum
				
				
			} else { // 2.2. Otherwise, make the Collection to add the Album to.
				createCollection(
					for: newMediaItem,
					via: managedObjectContext)
				// … and then try 2 again (risking an infinite loop).
				newAlbumToReturn = createAlbum(
					for: newMediaItem,
					via: managedObjectContext)
			}
		}
		
		
		guard let result = newAlbumToReturn else {
			fatalError("Couldn't make a new Album to add new Songs to.")
		}
		return result
		
		
	}
	
	private func createCollection(
		for newMediaItem: MPMediaItem,
		via managedObjectContext: NSManagedObjectContext
	) {
		// We should only be running this if we don't already have a managed object for the collection for the album for the song.
		managedObjectContext.performAndWait {
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
	
}
