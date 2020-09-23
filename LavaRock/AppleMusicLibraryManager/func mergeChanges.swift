//
//  func mergeChanges.swift
//  LavaRock
//
//  Created by h on 2020-08-15.
//

import CoreData
import MediaPlayer

extension AppleMusicLibraryManager {
	
	// This is where the magic happens. This is the engine that keeps our data structures matched up with the Apple Music library.
	final func mergeChanges() {
		let mainManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//		if shouldNextMergeBeSynchronous {
		managedObjectContext = mainManagedObjectContext // Set this again, just to be sure.
		managedObjectContext.performAndWait {
			mergeChangesPart2()
		}
//		} else {
		
//		}
		shouldNextMergeBeSynchronous = false
		managedObjectContext = mainManagedObjectContext // Set this again, just to be sure.
	}
	
	private func mergeChangesPart2() {
		
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
			toMatch: potentiallyModifiedMediaItems)
		createManagedObjects( // Create before deleting, because deleting also cleans up empty albums and collections, and we don't want to do that yet, because of what we mentioned above.
			// This might make new albums, and if it does, it might make new collections.
			for: newMediaItems,
			isAppDatabaseEmpty: wasAppDatabaseEmptyBeforeMerge,
			existingAlbums: existingAlbums,
			existingCollections: existingCollections)
		deleteManagedObjects(
			forSongsWith: objectIDsOfSongsToDelete)
		
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
			with: albumIDs)
		
		// TO DO: Take out the fetch above for albums. Instead, within each collection, recalculate the release date estimates; then, if wasAppDatabaseEmptyBeforeMerge, sort those albums from newest to oldest (based on the newly recalculated estimates).
		
		if wasAppDatabaseEmptyBeforeMerge {
			reindexAlbumsByNewestFirstWithinCollections(with: collectionIDs)
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
	
	// Only MPMediaItems have release dates, and those can't be albums.
	// An MPMediaItemCollection has a property representativeItem, but that item's release date doesn't necessarily represent the album's release date.
	// Instead, we'll estimate the albums' release dates and keep the estimates up to date.
	private func recalculateReleaseDateEstimatesForAlbums(
		with albumIDs: [NSManagedObjectID]
	) {
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
	
	private func reindexAlbumsByNewestFirstWithinCollections(
		with collectionIDs: [NSManagedObjectID]
	) {
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
