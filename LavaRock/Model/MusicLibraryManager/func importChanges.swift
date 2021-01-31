//
//  func importChanges.swift
//  LavaRock
//
//  Created by h on 2020-08-15.
//

import CoreData
import MediaPlayer
import OSLog

extension MusicLibraryManager {
	
	// This is where the magic happens. This is the engine that keeps our data structures matched up with the library in the built-in Music app.
	final func importChanges() {
		os_signpost(.begin, log: Self.importChangesMainLog, name: "0. Main")
		defer {
			os_signpost(.end, log: Self.importChangesMainLog, name: "0. Main")
		}
		
		managedObjectContext.performAndWait {
			importChangesMethodBody()
		}
	}
	
	// Remember: persistentIDs and albumPersistentIDs from the MediaPlayer framework are UInt64s, whereas we store them in Core Data as Int64s, so always use Int64(bitPattern: persistentID) when you deal with both Core Data and persistentIDs.
	private func importChangesMethodBody() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let queriedMediaItems = MPMediaQuery.songs().items
		else { return }
		
		os_signpost(.begin, log: Self.importChangesMainLog, name: "0a. Initial Parse")
		
		let songsFetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
		// Order doesn't matter, because this will end up being the array of Songs to be deleted.
		let savedSongs = managedObjectContext.objectsFetched(for: songsFetchRequest)
		let shouldImportIntoDefaultOrder = savedSongs.isEmpty
		
		/*
		var savedSongsCopy = savedSongs
		savedSongsCopy.sort { $0.index < $1.index }
		savedSongsCopy.sort { $0.container!.index < $1.container!.index }
		savedSongsCopy.sort { $0.container!.container!.index < $1.container!.container!.index }
		
		print("")
		for song in savedSongsCopy {
		print(song.titleFormattedOrPlaceholder())
		print("Collection \(song.container!.container!.index), Album \(song.container!.index), Song \(song.index)")
		}
		*/
		
		// Find out which of our saved Songs we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the MPMediaItems we haven't seen before. We'll make new managed objects for them.
		var potentiallyModifiedSongObjectIDs = [NSManagedObjectID]()
		var potentiallyModifiedMediaItems = [MPMediaItem]()
		var deletedSongObjectIDs = [NSManagedObjectID]()
		var queriedMediaItemsCopy = queriedMediaItems
		for savedSong in savedSongs {
			if let indexOfPotentiallyModifiedMediaItem = queriedMediaItemsCopy.firstIndex(where: { queriedMediaItem in
				savedSong.persistentID == Int64(bitPattern: queriedMediaItem.persistentID)
			}) { // We already have a Song for this MPMediaItem. We might have to update it.
				potentiallyModifiedSongObjectIDs.append(savedSong.objectID)
				let potentiallyModifiedMediaItem = queriedMediaItemsCopy[indexOfPotentiallyModifiedMediaItem]
				potentiallyModifiedMediaItems.append(potentiallyModifiedMediaItem)
				queriedMediaItemsCopy.remove(at: indexOfPotentiallyModifiedMediaItem)
				
			} else { // This Song no longer corresponds to any MPMediaItem in the Music library. We'll delete it.
				deletedSongObjectIDs.append(savedSong.objectID)
			}
		}
		// queriedMediaItems now holds the MPMediaItems that we don't have records of. We'll make new Songs for these.
		let newMediaItems = queriedMediaItemsCopy
		
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
		print("Deleted songs: \(deletedSongObjectIDs.count)")
		for songID in deletedSongObjectIDs {
			let song = managedObjectContext.object(with: songID) as! Song
			print(song.persistentID)
		}
		*/
		
		os_signpost(.end, log: Self.importChangesMainLog, name: "0a. Initial Parse")
		
		updateManagedObjects( // Update before creating and deleting, so that we can easily put new Songs above modified Songs.
			// This might make new Albums, but not new Collections or Songs.
			// This doesn't delete any Songs, Albums, or Collections.
			// This might also leave behind empty Albums, because all the Songs in them were moved to other Albums; but we won't delete those empty Albums for now, so that if the user also added other Songs to those empty Albums, we can keep those Albums in the same place, instead of re-adding them to the top.
			forSongsWith: potentiallyModifiedSongObjectIDs,
			toMatch: potentiallyModifiedMediaItems)
		
		let existingAlbumsFetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
		// Order doesn't matter, because we identify Albums by their albumPersistentID.
		let existingAlbums = managedObjectContext.objectsFetched(for: existingAlbumsFetchRequest)
		
		let existingCollectionsFetchRequest: NSFetchRequest<Collection> = Collection.fetchRequest()
		// Order matters, because we'll try to add new Albums to the first Collection with a matching title.
		existingCollectionsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		let existingCollections = managedObjectContext.objectsFetched(for: existingCollectionsFetchRequest)
		
		createManagedObjects( // Create before deleting, because deleting also cleans up empty Albums and Collections, and we don't want to do that yet, because of what we mentioned above.
			// This might make new Albums, and if it does, it might make new Collections.
			for: newMediaItems,
			existingAlbums: existingAlbums,
			existingCollections: existingCollections)
		deleteManagedObjects(
			forSongsWith: deletedSongObjectIDs)
		
		// Then, some cleanup.
		
		os_signpost(.begin, log: Self.importChangesMainLog, name: "4. Cleanup")
		
		let allCollectionsFetchRequest: NSFetchRequest<Collection> = Collection.fetchRequest()
		// Order doesn't matter, because this is for reindexing the Albums within each Collection.
		let allCollections = managedObjectContext.objectsFetched(for: allCollectionsFetchRequest)
		
		let allAlbumsFetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
		// Order doesn't matter, because this is for recalculating each Album's release date estimate, and reindexing the Songs within each Album.
		let allAlbums = managedObjectContext.objectsFetched(for: allAlbumsFetchRequest)
		
		os_signpost(.begin, log: Self.cleanupLog, name: "Recalculate Album release date estimates")
		recalculateReleaseDateEstimates(
			for: allAlbums,
			considering: queriedMediaItems)
		os_signpost(.end, log: Self.cleanupLog, name: "Recalculate Album release date estimates")
		
		os_signpost(.begin, log: Self.cleanupLog, name: "Reindex all Albums and Songs")
		for collection in allCollections {
			reindexAlbums(
				in: collection,
				shouldSortByNewestFirst: shouldImportIntoDefaultOrder)
		}
		for album in allAlbums {
			reindexSongs(in: album)
		}
		os_signpost(.end, log: Self.cleanupLog, name: "Reindex all Albums and Songs")
		
		os_signpost(.end, log: Self.importChangesMainLog, name: "4. Cleanup")
		
		managedObjectContext.tryToSaveSynchronously()
//		managedObjectContext.parent?.tryToSaveSynchronously()
		DispatchQueue.main.async {
			NotificationCenter.default.post(
				Notification(name: Notification.Name.LRDidSaveChangesFromMusicLibrary)
			)
		}
	}
	
	// MARK: - Cleanup
	
	private static let cleanupLog = OSLog(
		subsystem: subsystemForOSLog,
		category: "4. Cleanup")
	
	// MARK: Recalculating Release Date Estimates
	
	// Only MPMediaItems have release dates, and those can't be albums.
	// An MPMediaItemCollection has a property representativeItem, but that item's release date doesn't necessarily represent the album's release date.
	// Instead, we'll estimate the albums' release dates and keep the estimates up to date.
	private func recalculateReleaseDateEstimates(
		for albums: [Album],
		considering queriedMediaItems: [MPMediaItem]
	) {
		os_signpost(.begin, log: Self.cleanupLog, name: "Filter out MPMediaItems without releaseDates")
		var queriedMediaItemsCopy = Set(queriedMediaItems).filter {
			$0.releaseDate != nil
		}
		os_signpost(.end, log: Self.cleanupLog, name: "Filter out MPMediaItems without releaseDates")
		
		for album in albums {
			// Update one Album's release date estimate.
			os_signpost(.begin, log: Self.cleanupLog, name: "Recalculate release date estimate for one Album")
			
			album.releaseDateEstimate = nil
			
			// Find the MPMediaItems associated with this Album.
			// Don't use song.mpMediaItem() for every Song; it's way too slow.
			let thisAlbumPersistentID = album.albumPersistentID
			os_signpost(.begin, log: Self.cleanupLog, name: "Filter all MPMediaItems down to the ones associated with this Album")
			let matchingQueriedMediaItems = queriedMediaItemsCopy.filter {
				Int64(bitPattern: $0.albumPersistentID) == thisAlbumPersistentID
			}
			os_signpost(.end, log: Self.cleanupLog, name: "Filter all MPMediaItems down to the ones associated with this Album")
			
			// Determine the new release date estimate, using those MPMediaItems.
			for mediaItem in matchingQueriedMediaItems {
				defer {
					queriedMediaItemsCopy.remove(mediaItem)
				}
				
				guard let competingEstimate = mediaItem.releaseDate else { continue }
				
				if album.releaseDateEstimate == nil {
					album.releaseDateEstimate = competingEstimate // Same as below
				} else if
					let currentEstimate = album.releaseDateEstimate,
					competingEstimate > currentEstimate
				{
					album.releaseDateEstimate = competingEstimate // Same as above
				}
			}
			
			os_signpost(.end, log: Self.cleanupLog, name: "Recalculate release date estimate for one Album")
		}
	}
	
	// MARK: - Reindexing Albums
	
	private func reindexAlbums(
		in collection: Collection,
		shouldSortByNewestFirst: Bool
	) {
		guard let contentsOfCollection = collection.contents else { return }
		
		var albumsInCollection = [Album]()
		for element in contentsOfCollection {
			let albumInCollection = element as! Album
			albumsInCollection.append(albumInCollection)
		}
		
		albumsInCollection.sort { $0.index < $1.index } // Sort by index here even if we're going to sort by release date later; this keeps Albums whose releaseDateEstimate is nil in their previous order.
		if shouldSortByNewestFirst {
			albumsInCollection = sortedByNewestFirstAndUnknownReleaseDateLast(albums: albumsInCollection)
		}
		
		for index in 0 ..< albumsInCollection.count {
			let album = albumsInCollection[index]
			album.index = Int64(index)
		}
	}
	
	private func sortedByNewestFirstAndUnknownReleaseDateLast(albums albumsImmutable: [Album]) -> [Album] {
		var albumsCopy = albumsImmutable
		
		let commonDate = Date()
		albumsCopy.sort {
			$0.releaseDateEstimate ?? commonDate >= // This reverses the order of all Albums whose releaseDateEstimate is nil.
				$1.releaseDateEstimate ?? commonDate
		}
		albumsCopy.sort { (firstAlbum, _) in
			firstAlbum.releaseDateEstimate == nil // This re-reverses the order of all Albums whose releaseDateEstimate is nil.
		}
		
		return albumsCopy
	}
	
	// MARK: - Reindexing Songs
	
	private func reindexSongs(in album: Album) {
		guard let contentsOfAlbum = album.contents else { return }
		
		var songsInAlbum = [Song]()
		for element in contentsOfAlbum {
			let songInAlbum = element as! Song
			songsInAlbum.append(songInAlbum)
		}
		
		songsInAlbum.sort { $0.index < $1.index }
		
		for index in 0 ..< songsInAlbum.count {
			let song = songsInAlbum[index]
			song.index = Int64(index)
		}
	}
	
}
