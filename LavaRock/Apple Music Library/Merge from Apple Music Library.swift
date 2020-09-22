//
//  Merge from Apple Music Library.swift
//  LavaRock
//
//  Created by h on 2020-08-15.
//

import CoreData
import MediaPlayer

extension AppleMusicLibraryManager {
	
	// This is where the magic happens. This is the engine that keeps our data structures matched up with the Apple Music library.
	final func mergeChanges() {
//		if shouldNextMergeBeSynchronous {
		let mainManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		mainManagedObjectContext.performAndWait {
			mergeChangesPart2(via: mainManagedObjectContext)
		}
//		} else {
		
//		}
		shouldNextMergeBeSynchronous = false
	}
	
	private func mergeChangesPart2(via managedObjectContext: NSManagedObjectContext) {
		
		// Remember: persistentIDs and albumPersistentIDs from the MediaPlayer framework are UInt64s, whereas we store them in Core Data as Int64s, so always use Int64(bitPattern: persistentID) when you deal with both Core Data and persistentIDs.
		
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			var queriedMediaItems = MPMediaQuery.songs().items
		else { return }
		
		let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
		// Order doesn't matter, because this will end up being the array of songs to be deleted.
		let savedSongs = managedObjectContext.objectsFetched(for: songsFetchRequest) as! [Song]
		let wasAppDatabaseEmptyBeforeMerge = savedSongs.count == 0
		
		let existingAlbumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
		// Does order matter?
//		existingAlbumsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		let existingAlbums = managedObjectContext.objectsFetched(for: existingAlbumsFetchRequest) as! [Album]
		
		let existingCollectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
		// Does order matter?
		let existingCollections = managedObjectContext.objectsFetched(for: existingCollectionsFetchRequest) as! [Collection]
		
		
		var savedSongsCopy = savedSongs
		savedSongsCopy.sort() { $0.index < $1.index }
		savedSongsCopy.sort() { $0.container!.index < $1.container!.index }
		savedSongsCopy.sort() { $0.container!.container!.index < $1.container!.container!.index }
		
		print("")
		for song in savedSongsCopy {
		print(song.titleFormattedOrPlaceholder())
		print("Container \(song.container!.container!.index), album \(song.container!.index), song \(song.index)")
		}
		
		
		// Find out which of our saved Songs we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the MPMediaItems we haven't seen before. We'll make new managed objects for them.
		var potentiallyModifiedSongObjectIDs = [NSManagedObjectID]()
		var potentiallyModifiedMediaItems = [MPMediaItem]()
		var objectIDsOfSongsToDelete = [NSManagedObjectID]()
		for savedSong in savedSongs {
			if let indexOfPotentiallyModifiedMediaItem = queriedMediaItems.firstIndex(where: { queriedMediaItem in
				savedSong.persistentID == Int64(bitPattern: queriedMediaItem.persistentID)
			}) { // We already have a record of (a Song for) this MPMediaItem. We might have to update it.
				potentiallyModifiedSongObjectIDs.append(savedSong.objectID)
				let potentiallyModifiedMediaItem = queriedMediaItems[indexOfPotentiallyModifiedMediaItem]
				potentiallyModifiedMediaItems.append(potentiallyModifiedMediaItem)
				queriedMediaItems.remove(at: indexOfPotentiallyModifiedMediaItem)
				
			} else { // This Song no longer corresponds to any MPMediaItem in the Apple Music library. We'll remove it from our records.
				objectIDsOfSongsToDelete.append(savedSong.objectID)
			}
		}
		// queriedMediaItems now holds the MPMediaItems that we don't have records of. We'll make new Songs for these.
		let newMediaItems = queriedMediaItems
		
		/*
		print("")
		print("Potentially modified songs: \(potentiallyModifiedMediaItems.count)")
		for item in potentiallyModifiedMediaItems {
			print("\(String(describing: item.title)): \(item.persistentID)")
		}
		print("")
		print("Added songs: \(newMediaItems.count)")
		for item in newMediaItems {
			print("\(String(describing: item.title)): \(item.persistentID)")
		}
		print("")
		print("Deleted songs: \(objectIDsOfSongsToDelete.count)")
		for songID in objectIDsOfSongsToDelete {
			let song = managedObjectContext.object(with: songID) as! Song
			print(song.persistentID)
		}
		*/
		
		updateManagedObjects( // Update before creating and deleting, so that we can put new songs above modified songs (easily).
			// This might make new albums, but not new collections.
			// This might also leave behind empty albums, because all the songs in them were moved to other albums; but we won't delete those empty albums for now, so that if the user also added other songs to those empty albums, we can keep those albums in the same place, instead of re-adding them to the top.
			forSongsWith: potentiallyModifiedSongObjectIDs,
			toMatch: potentiallyModifiedMediaItems,
			via: managedObjectContext)
		createManagedObjects( // Create before deleting, because deleting also cleans up empty albums and collections, and we don't want to do that yet, because of what we mentioned above.
			// This might make new albums, and if it does, it might make new collections.
			for: newMediaItems,
			isAppDatabaseEmpty: wasAppDatabaseEmptyBeforeMerge,
			existingAlbums: existingAlbums,
			existingCollections: existingCollections,
			via: managedObjectContext)
		deleteManagedObjects(
			forSongsWith: objectIDsOfSongsToDelete,
			via: managedObjectContext)
		
		// Then, some cleanup.
		
		var collectionIDs = [NSManagedObjectID]()
		let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
		// Order doesn't matter.
		let allCollections = managedObjectContext.objectsFetched(for: collectionsFetchRequest) as! [Collection]
		for collection in allCollections {
			collectionIDs.append(collection.objectID)
		}
		
		var albumIDs = [NSManagedObjectID]()
		let allAlbumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
		// Order doesn't matter.
		let allAlbums = managedObjectContext.objectsFetched(for: allAlbumsFetchRequest) as! [Album]
		for album in allAlbums {
			albumIDs.append(album.objectID)
		}
		
		recalculateReleaseDateEstimatesForAlbums(
			with: albumIDs,
			via: managedObjectContext)
		
		// TO DO: Take out the fetch above for albums. Instead, within each collection, recalculate the release date estimates; then, if wasAppDatabaseEmptyBeforeMerge, sort those albums from newest to oldest (based on the newly recalculated estimates).
		
		if wasAppDatabaseEmptyBeforeMerge {
			reindexAlbumsByNewestFirstWithinCollections(
				with: collectionIDs,
				via: managedObjectContext)
		}
		
		managedObjectContext.tryToSaveSynchronously()
//		managedObjectContext.parent?.tryToSaveSynchronously()
		DispatchQueue.main.async {
			NotificationCenter.default.post(
				Notification(name: Notification.Name.LRDidSaveChangesFromAppleMusic)
			)
		}
	}
	
	// MARK: - Update Managed Objects
	
	private func updateManagedObjects(
		forSongsWith songIDs: [NSManagedObjectID],
		toMatch mediaItems: [MPMediaItem],
		via managedObjectContext: NSManagedObjectContext
	) {
		// Here, you can update any stored attributes on each song. But unless we have to, it's best to not store that data in the first place, because we'll have to manually keep up to date.
		
		updateRelationshipsBetweenAlbumsAndSongs(
			with: songIDs,
			toMatch: mediaItems,
			via: managedObjectContext)
	}
	
	private func updateRelationshipsBetweenAlbumsAndSongs(
		with songIDs: [NSManagedObjectID],
		toMatch mediaItems: [MPMediaItem],
		via managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			
			var potentiallyOutdatedSongs = [Song]()
			for songID in songIDs {
				let song = managedObjectContext.object(with: songID) as! Song
				potentiallyOutdatedSongs.append(song)
			}
			
			potentiallyOutdatedSongs.sort() { $0.index < $1.index }
			potentiallyOutdatedSongs.sort() { $0.container!.index < $1.container!.index }
			potentiallyOutdatedSongs.sort() { $0.container!.container!.index < $1.container!.container!.index }
			/*
			print("")
			for song in potentiallyOutdatedSongs {
				print(song.titleFormattedOrPlaceholder())
				print("Container \(song.container!.container!.index), album \(song.container!.index), song \(song.index)")
			}
			*/
			
			var knownAlbumPersistentIDs = [Int64]()
			var existingAlbums = [Album]()
			for song in potentiallyOutdatedSongs {
				knownAlbumPersistentIDs.append(song.container!.albumPersistentID)
				existingAlbums.append(song.container!)
			}
			
			for song in potentiallyOutdatedSongs.reversed() {
				
				let knownAlbumPersistentID = song.container!.albumPersistentID
				let newAlbumPersistentID = song.mpMediaItem()!.albumPersistentID
				/*
				print("")
				print("Checking album status of \(song.titleFormattedOrPlaceholder()).")
				print("Previously known albumPersistentID: \(UInt64(bitPattern: knownAlbumPersistentID))")
				print("New albumPersistentID: \(newAlbumPersistentID)")
				*/
				
				if knownAlbumPersistentID == Int64(bitPattern: newAlbumPersistentID) {
					continue
					
				} else { // This is a song we recognize, but its albumPersistentID has changed.
					
					if !knownAlbumPersistentIDs.contains(Int64(bitPattern: newAlbumPersistentID)) {
						
						// We've never seen this albumPersistentID before, so make a new album for it.
						
						knownAlbumPersistentIDs.append(Int64(bitPattern: newAlbumPersistentID))
						let newAlbum = Album(context: managedObjectContext)
						existingAlbums.append(newAlbum)
						
						newAlbum.container = song.container!.container!
						for album in newAlbum.container!.contents! { // For each album in the same collection as the new album
							(album as! Album).index += 1
						}
						newAlbum.index = 0
						newAlbum.albumPersistentID = Int64(bitPattern: newAlbumPersistentID)
						// We'll set releaseDateEstimate later.
						
						song.index = 0 //
						song.container = newAlbum
						
					} else {
						
						// This song's albumPersistentID has changed, but we already have an album for it, so add it to that album.
						
						knownAlbumPersistentIDs.append(Int64(bitPattern: newAlbumPersistentID))
						let existingAlbum = existingAlbums.first(where: { existingAlbum in
							existingAlbum.albumPersistentID == Int64(bitPattern: newAlbumPersistentID)
						})!
						
						for song in existingAlbum.contents! {
							(song as! Song).index += 1
						}
						song.index = 0 //
						song.container = existingAlbum
					}
					
					// We'll delete empty albums (and collections) later.
					
				}
				
			}
			
		}
	}
	
	// MARK: - Creating Managed Objects
	
	// Make new managed objects for the new media items, including new Albums and Collections to put them in if necessary.
	private func createManagedObjects(
		for newMediaItems: [MPMediaItem],
		isAppDatabaseEmpty: Bool,
		existingAlbums: [Album],
		existingCollections: [Collection],
		via managedObjectContext: NSManagedObjectContext
	) {
//		guard newMediaItems.count >= 1 else { return } // Only speeds up launch time by ~1 frame
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
		
		
		/*
		let mediaItemsSortedInReverse = sortedInReverseTargetOrder(
			mediaItems: mediaItems,
			isAppDatabaseEmpty: isAppDatabaseEmpty)
		
		for mediaItem in mediaItemsSortedInReverse {
			
			/*
			// Trying to filter out music videos (and giving up on it)
			guard mediaItem.mediaType != .musicVideo else { // Apparently music videos don't match MPMediaType.musicVideo
			guard mediaItem.mediaType != .anyVideo else { // This doesn't work either
			if mediaItem.mediaType.rawValue == UInt(2049) { // This works, but seems fragile
				print(mediaItem.albumTitle)
				print(mediaItem.title)
				print(mediaItem.albumPersistentID)
				print(mediaItem.persistentID)
				continue
			}
			*/
			
			createManagedObjects(
				for: mediaItem,
				via: managedObjectContext)
		}
		*/
	}
	
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
//				||
//
//					songs[0].mpMediaItem()?.discNumber ?? 1 < songs[1].mpMediaItem()?.discNumber ?? 1
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
	
	// MARK: - Deleting Managed Objects
	
	private func deleteManagedObjects(
		forSongsWith songIDs: [NSManagedObjectID],
		via managedObjectContext: NSManagedObjectContext
	) { // then clean up empty albums, then clean up empty collections
		managedObjectContext.performAndWait {
			for songID in songIDs {
				let songToDelete = managedObjectContext.object(with: songID)
				managedObjectContext.delete(songToDelete)
			}
		}
		
		deleteEmptyAlbums(via: managedObjectContext)
		deleteEmptyCollections(via: managedObjectContext)
	}
	
	private func deleteEmptyAlbums(
		via managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
			// Order doesn't matter.
			let allAlbums = managedObjectContext.objectsFetched(for: albumsFetchRequest) as! [Album]
			
			for album in allAlbums {
				guard
					let contents = album.contents,
					contents.count == 0
				else { continue }
				managedObjectContext.delete(album)
				// TO DO: This leaves gaps in the album indexes within each collection.
			}
		}
	}
	
	private func deleteEmptyCollections(
		via managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
			// Order doesn't matter.
			let allCollections = managedObjectContext.objectsFetched(for: collectionsFetchRequest) as! [Collection]
			
			for collection in allCollections {
				guard
					let contents = collection.contents,
					contents.count == 0
				else { continue }
				managedObjectContext.delete(collection)
				// TO DO: This leaves gaps in the collection indexes.
			}
		}
	}
	
	// MARK: - Cleanup
	
	// Only MPMediaItems have release dates, and those can't be albums.
	// An MPMediaItemCollection has a property representativeItem, but that item's release date doesn't necessarily represent the album's release date.
	// Instead, we'll estimate the albums' release dates and keep the estimates up to date.
	private func recalculateReleaseDateEstimatesForAlbums(
		with albumIDs: [NSManagedObjectID],
		via managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			for albumID in albumIDs {
				// Update one album's release date estimate.
				let album = managedObjectContext.object(with: albumID) as! Album
				// Should we get the songs using mpMediaItemCollection() instead of Core Data?
				
				let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
				songsFetchRequest.predicate = NSPredicate(format: "container == %@", album)
				// Order doesn't matter.
				let songsInAlbum = managedObjectContext.objectsFetched(for: songsFetchRequest) as! [Song]
				
				album.releaseDateEstimate = nil
				
				for song in songsInAlbum {
					guard let competingEstimate = song.mpMediaItem()?.releaseDate else { continue }
					
					if album.releaseDateEstimate == nil {
						album.releaseDateEstimate = competingEstimate // Same as below
					} else if
						let currentEstimate = album.releaseDateEstimate,
						competingEstimate > currentEstimate
					{
						album.releaseDateEstimate = competingEstimate // Same as above
					}
				}
			}
		}
	}
	
	private func reindexAlbumsByNewestFirstWithinCollections(
		with collectionIDs: [NSManagedObjectID],
		via managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			for collectionID in collectionIDs {
				let collection = managedObjectContext.object(with: collectionID) as! Collection
				
				let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
				albumsFetchRequest.predicate = NSPredicate(format: "container == %@", collection)
				albumsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
				var albumsInCollection = managedObjectContext.objectsFetched(for: albumsFetchRequest) as! [Album]
				
				let commonDate = Date()
				albumsInCollection.sort() {
					$0.releaseDateEstimate ?? commonDate >=
						$1.releaseDateEstimate ?? commonDate
				}
				albumsInCollection.sort() { (firstAlbum, _) in
					firstAlbum.releaseDateEstimate == nil
				}
				
				for index in 0..<albumsInCollection.count {
					let album = albumsInCollection[index]
					album.index = Int64(index)
				}
			}
		}
	}
	
}
