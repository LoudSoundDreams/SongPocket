//
//  func importChanges.swift
//  LavaRock
//
//  Created by h on 2020-08-15.
//

import CoreData
import MediaPlayer

extension AppleMusicLibraryManager {
	
	// This is where the magic happens. This is the engine that keeps our data structures matched up with the Apple Music library.
	final func importChanges() {
		let mainManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//		if shouldNextImportBeSynchronous {
		managedObjectContext = mainManagedObjectContext // Set this again, just to be sure.
		managedObjectContext.performAndWait {
			importChangesPart2()
		}
//		} else {
		
//		}
		shouldNextImportBeSynchronous = false
		managedObjectContext = mainManagedObjectContext // Set this again, just to be sure.
	}
	
	// Remember: persistentIDs and albumPersistentIDs from the MediaPlayer framework are UInt64s, whereas we store them in Core Data as Int64s, so always use Int64(bitPattern: persistentID) when you deal with both Core Data and persistentIDs.
	private func importChangesPart2() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			var queriedMediaItems = MPMediaQuery.songs().items
		else { return }
		
		let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
		// Order doesn't matter, because this will end up being the array of Songs to be deleted.
		let savedSongs = managedObjectContext.objectsFetched(for: songsFetchRequest) as! [Song]
		let shouldImportIntoDefaultOrder = savedSongs.count == 0
		
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
		for savedSong in savedSongs {
			if let indexOfPotentiallyModifiedMediaItem = queriedMediaItems.firstIndex(where: { queriedMediaItem in
				savedSong.persistentID == Int64(bitPattern: queriedMediaItem.persistentID)
			}) { // We already have a Song for this MPMediaItem. We might have to update it.
				potentiallyModifiedSongObjectIDs.append(savedSong.objectID)
				let potentiallyModifiedMediaItem = queriedMediaItems[indexOfPotentiallyModifiedMediaItem]
				potentiallyModifiedMediaItems.append(potentiallyModifiedMediaItem)
				queriedMediaItems.remove(at: indexOfPotentiallyModifiedMediaItem)
				
			} else { // This Song no longer corresponds to any MPMediaItem in the Apple Music library. We'll delete it.
				deletedSongObjectIDs.append(savedSong.objectID)
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
		print("Deleted songs: \(deletedSongObjectIDs.count)")
		for songID in deletedSongObjectIDs {
			let song = managedObjectContext.object(with: songID) as! Song
			print(song.persistentID)
		}
		*/
		
		updateManagedObjects( // Update before creating and deleting, so that we can easily put new Songs above modified Songs.
			// This might make new Albums, but not new Collections or Songs.
			// This doesn't delete any Songs, Albums, or Collections.
			// This might also leave behind empty Albums, because all the Songs in them were moved to other Albums; but we won't delete those empty Albums for now, so that if the user also added other Songs to those empty Albums, we can keep those Albums in the same place, instead of re-adding them to the top.
			forSongsWith: potentiallyModifiedSongObjectIDs,
			toMatch: potentiallyModifiedMediaItems)
		
		let existingAlbumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
		// Order doesn't matter, because we identify Albums by their albumPersistentID.
		let existingAlbums = managedObjectContext.objectsFetched(for: existingAlbumsFetchRequest) as! [Album]
		
		let existingCollectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
		// Order matters, because we'll try to add new Albums to the first Collection with a matching title.
		existingCollectionsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		let existingCollections = managedObjectContext.objectsFetched(for: existingCollectionsFetchRequest) as! [Collection]
		
		createManagedObjects( // Create before deleting, because deleting also cleans up empty Albums and Collections, and we don't want to do that yet, because of what we mentioned above.
			// This might make new Albums, and if it does, it might make new Collections.
			for: newMediaItems,
			existingAlbums: existingAlbums,
			existingCollections: existingCollections)
		deleteManagedObjects(
			forSongsWith: deletedSongObjectIDs)
		
		// Then, some cleanup.
		
		let allCollectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
		// Order doesn't matter, because this is for reindexing the Albums within each Collection.
		let allCollections = managedObjectContext.objectsFetched(for: allCollectionsFetchRequest) as! [Collection]
		
		let allAlbumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
		// Order doesn't matter, because this is for recalculating each Album's release date estimate, and reindexing the Songs within each Album.
		let allAlbums = managedObjectContext.objectsFetched(for: allAlbumsFetchRequest) as! [Album]
		var albumIDs = [NSManagedObjectID]()
		for album in allAlbums {
			albumIDs.append(album.objectID)
		}
		
		recalculateReleaseDateEstimatesForAlbums(
			with: albumIDs)
		
		for collection in allCollections {
			reindexAlbums(
				in: collection,
				shouldSortByNewestFirst: shouldImportIntoDefaultOrder)
		}
		
		for album in allAlbums {
			reindexSongs(in: album)
		}
		
		managedObjectContext.tryToSaveSynchronously()
//		managedObjectContext.parent?.tryToSaveSynchronously()
		DispatchQueue.main.async {
			NotificationCenter.default.post(
				Notification(name: Notification.Name.LRDidSaveChangesFromAppleMusic)
			)
		}
	}
	
	// MARK: - Cleanup
	
	// MARK: Recalculating Release Date Estimates
	
	// Only MPMediaItems have release dates, and those can't be albums.
	// An MPMediaItemCollection has a property representativeItem, but that item's release date doesn't necessarily represent the album's release date.
	// Instead, we'll estimate the albums' release dates and keep the estimates up to date.
	private func recalculateReleaseDateEstimatesForAlbums(
		with albumIDs: [NSManagedObjectID]
	) {
		for albumID in albumIDs {
			// Update one Album's release date estimate.
			let album = managedObjectContext.object(with: albumID) as! Album
			// Should we get the Songs using mpMediaItemCollection() instead of Core Data?
			
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
