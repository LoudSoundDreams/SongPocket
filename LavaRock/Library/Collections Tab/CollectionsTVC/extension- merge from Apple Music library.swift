//
//  extension- merge from Apple Music library.swift
//  LavaRock
//
//  Created by h on 2020-08-15.
//

import UIKit
import CoreData
import MediaPlayer

//class AppleMusicLibraryMerger { // Move this to MediaPlayerManager?
// If so, refactor CoreDataManager first? / Or inject a managed object context as a dependency
extension CollectionsTVC {
	
	// This is where the magic happens. This is the engine that keeps our data structures matched up with items in the Apple Music library.
	func mergeChangesFromAppleMusicLibrary(/*managedObjectContext: NSManagedObjectContext*/) {
		
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			var queriedMediaItems = MPMediaQuery.songs().items
		else { return }
		
		let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
		// Order doesn't matter, because this will end up being the array of songs to be deleted.
		var savedSongs = coreDataManager.managedObjects(for: songsFetchRequest) as! [Song]
		
		let wasAppDatabaseEmptyBeforeMerge = savedSongs.count == 0
		
		// Separate our saved songs into the ones that have been deleted, and the ones that have been potentially modified.
		var potentiallyModifiedMediaItems = [MPMediaItem]()
		var objectIDsOfPotentiallyModifiedSongs = [NSManagedObjectID]()
		for queriedMediaItem in queriedMediaItems {
			if let indexOfPotentiallyModifiedSong = savedSongs.firstIndex(where: { savedSong in
				Int64(bitPattern: queriedMediaItem.persistentID) == savedSong.persistentID // We already have a record of this song. We need to check whether to update it.
			})
			{
				potentiallyModifiedMediaItems.append(queriedMediaItem)
				objectIDsOfPotentiallyModifiedSongs.append(savedSongs[indexOfPotentiallyModifiedSong].objectID)
				savedSongs.remove(at: indexOfPotentiallyModifiedSong)
			}
		}
		// savedSongs now holds the songs that have been deleted from the Apple Music library.
		var objectIDsOfSongsToDelete = [NSManagedObjectID]()
		for songToDelete in savedSongs {
			objectIDsOfSongsToDelete.append(songToDelete.objectID)
		}
		
		// From the list of queried IDs, remove the IDs of songs we've noted as potentially modified, only keeping the IDs of new songs.
		for potentiallyModifiedMediaItem in potentiallyModifiedMediaItems {
			if let index = queriedMediaItems.firstIndex(where: { queriedMediaItem in
				Int64(bitPattern: potentiallyModifiedMediaItem.persistentID) == queriedMediaItem.persistentID
			})
			{
				queriedMediaItems.remove(at: index)
			}
		}
		let newMediaItems = queriedMediaItems
		
		print("")
		print("Potentially modified songs: \(potentiallyModifiedMediaItems.count)")
		for item in potentiallyModifiedMediaItems {
			print("")
			print("\(String(describing: item.albumTitle)): \(item.albumPersistentID)")
			print("\(String(describing: item.title)): \(item.persistentID)")
		}
		print("")
		print("Added songs: \(newMediaItems.count)")
		for item in newMediaItems {
			print("")
			print("\(String(describing: item.albumTitle)): \(item.albumPersistentID)")
			print("\(String(describing: item.title)): \(item.persistentID)")
		}
		print("")
		print("Deleted songs: \(objectIDsOfSongsToDelete.count)")
		
		updateManagedObjects(
			forSongsWith: objectIDsOfPotentiallyModifiedSongs,
			toMatch: potentiallyModifiedMediaItems) // Create and delete before updating. That way, we can update each song's index attribute within its album.
		createManagedObjects( // Create before deleting. That way, for example, if you deleted all the songs from an album, but added other songs from that album, that album will stay in the same place in this app.
			for: newMediaItems,
			isAppDatabaseEmpty: wasAppDatabaseEmptyBeforeMerge)
		deleteManagedObjects(forSongsWith: objectIDsOfSongsToDelete)
		
		// Now, some cleanup.
		
		var collectionIDs = [NSManagedObjectID]()
		let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
		// Order doesn't matter.
		let allCollections = coreDataManager.managedObjects(for: collectionsFetchRequest) as! [Collection]
		for collection in allCollections {
			collectionIDs.append(collection.objectID)
		}
		
		var albumIDs = [NSManagedObjectID]()
		let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
		// Order doesn't matter.
		let allAlbums = coreDataManager.managedObjects(for: albumsFetchRequest) as! [Album]
		for album in allAlbums {
			albumIDs.append(album.objectID)
		}
		
//		var songIDs = [NSManagedObjectID]()
//		let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
//		// Order doesn't matter.
//		let allSongs = coreDataManager.managedObjects(for: songsFetchRequest) as! [Song]
//		for song in allSongs {
//			songIDs.append(song.objectID)
//		}
		
		recalculateReleaseDateEstimatesFor(albumsWithObjectIDs: albumIDs)
		
		if wasAppDatabaseEmptyBeforeMerge {
			reindexAlbumsWithinEachCollectionByNewestFirst(objectIDsOfCollections: collectionIDs)
		}
		
		coreDataManager.save()
	}
	
	// MARK: - Update Managed Objects
	
	func updateManagedObjects(
		forSongsWith objectIDsOfSongsToUpdate: [NSManagedObjectID],
		toMatch mediaItems: [MPMediaItem]//,
	) {
		coreDataManager.managedObjectContext.performAndWait {
			
			for index in 0 ..< objectIDsOfSongsToUpdate.count {
				let songID = objectIDsOfSongsToUpdate[index]
				let song = coreDataManager.managedObjectContext.object(with: songID) as! Song
				let mediaItem = mediaItems[index]
				
				song.discNumber = Int64(mediaItem.discNumber) // MPMediaItem returns non-optional Int. `0` is null or unknown.
				song.trackNumber = Int64(mediaItem.albumTrackNumber) // MPMediaItem returns non-optional Int. `0` is null or unknown.
			}
			
		}
		
		updateRelationshipsBetweenAlbumsAndSongs(
			with: objectIDsOfSongsToUpdate,
			toMatch: mediaItems
		)
	}
	
	func updateRelationshipsBetweenAlbumsAndSongs(
		with objectIDsOfSongs: [NSManagedObjectID],
		toMatch mediaItems: [MPMediaItem]
	) {
		coreDataManager.managedObjectContext.performAndWait {
			
			var potentiallyOutdatedSongs = [Song]()
			for songID in objectIDsOfSongs {
				let song = coreDataManager.managedObjectContext.object(with: songID) as! Song
				potentiallyOutdatedSongs.append(song)
			}
			
			potentiallyOutdatedSongs.sort() { $0.index < $1.index }
			potentiallyOutdatedSongs.sort() { $0.container!.index < $1.container!.index }
			potentiallyOutdatedSongs.sort() { $0.container!.container!.index < $1.container!.container!.index }
			print("")
			for song in potentiallyOutdatedSongs {
				print(song.titleFormattedOrPlaceholder())
				print("Container index: \(song.container!.container!.index), album index: \(song.container!.index), song index: \(song.index)")
			}
			
			var allPreviouslyKnownAlbumPersistentIDs = [Int64]()
			for song in potentiallyOutdatedSongs {
				allPreviouslyKnownAlbumPersistentIDs.append(song.container!.albumPersistentID)
			}
			
//			var newAlbumPersistentIDsThatWeHaveAlreadyMadeNewAlbumsFor = [MPMediaEntityPersistentID]()
			
			var existingAlbums = [Album]()
			for song in potentiallyOutdatedSongs {
				let previouslyExistingAlbum = song.container!
				existingAlbums.append(previouslyExistingAlbum)
			}
			
			for song in potentiallyOutdatedSongs.reversed() {
				
				let newAlbumPersistentID = song.mpMediaItem()!.albumPersistentID
				print("")
				print("Checking album status of \(song.titleFormattedOrPlaceholder()).")
				print("New albumPersistentID: \(newAlbumPersistentID)")
				
				let previouslyKnownAlbumPersistentID = song.container!.albumPersistentID
				print("Previously known albumPersistentID: \(UInt64(bitPattern: previouslyKnownAlbumPersistentID))")
				if previouslyKnownAlbumPersistentID == Int64(bitPattern: newAlbumPersistentID) {
					
					print("This song's albumPersistentID hasn't changed. Moving on to the next song.")
					continue
					
				} else { // This is a song we recognize, but its albumPersistentID has changed.
					
					print("This song's albumPersistentID has changed.")
					
					if !allPreviouslyKnownAlbumPersistentIDs.contains(Int64(bitPattern: newAlbumPersistentID)) {
						allPreviouslyKnownAlbumPersistentIDs.append(Int64(bitPattern: newAlbumPersistentID))
//						newAlbumPersistentIDsThatWeHaveAlreadyMadeNewAlbumsFor.append(newAlbumPersistentID)
						let newAlbum = Album(context: coreDataManager.managedObjectContext)
						existingAlbums.append(newAlbum)
						
						newAlbum.container = song.container!.container!
						let container = newAlbum.container!
						for album in container.contents! {
							let albumInCollection = album as! Album
							albumInCollection.index += 1
						}
						newAlbum.index = 0
						newAlbum.albumPersistentID = Int64(bitPattern: newAlbumPersistentID)
						// We'll set the releaseDateEstimate attribute later.
						
						song.index = 0
						song.container = newAlbum
						
						print("We've never seen this albumPersistentID before, so we made a new album for it.")
						
					} else {
						
						allPreviouslyKnownAlbumPersistentIDs.append(Int64(bitPattern: newAlbumPersistentID))
//						newAlbumPersistentIDsThatWeHaveAlreadyMadeNewAlbumsFor.append(
//							Int64(bitPattern: newAlbumPersistentID)
//						)
						
						let existingAlbum = existingAlbums.first(where: { existingAlbum in
							existingAlbum.albumPersistentID == Int64(bitPattern: newAlbumPersistentID)
						})!
						
						for song in existingAlbum.contents! {
							let existingSong = song as! Song
							existingSong.index += 1
						}
						song.index = 0
						song.container = existingAlbum
						
						let collection = existingAlbum.container!
						for album in collection.contents! {
							let albumInCollection = album as! Album
							albumInCollection.index += 1
						}
						existingAlbum.index = 0
						
						print("This song's albumPersistentID has changed, but we already have an album for it, so we added it to that album.")
					}
				}
				
			}
			
		}
	}
	
	
	
	// MARK: - Creating Managed Objects
	
	func createManagedObjects(for newMediaItemsImmutable: [MPMediaItem], isAppDatabaseEmpty: Bool) {
		let newMediaItemsSortedInReverse = sortedInReverseTargetOrder(
			mediaItems: newMediaItemsImmutable,
			isAppDatabaseEmpty: isAppDatabaseEmpty)
		
		// Make new managed objects for the new songs, adding containers for them if necessary.
		for newMediaItem in newMediaItemsSortedInReverse {
			
			// Trying to filter out music videos (and giving up on it)
//			guard newMediaItem.mediaType != .musicVideo else { // Apparently music videos don't match MPMediaType.musicVideo
//			guard newMediaItem.mediaType != .anyVideo else { // This doesn't work either
//			if newMediaItem.mediaType.rawValue == UInt(2049) { // This works, but seems fragile
//				print(newMediaItem.albumArtist)
//				print(newMediaItem.albumTitle)
//				print(newMediaItem.title)
//				print(newMediaItem.artist)
//				print(newMediaItem.persistentID)
//				print(newMediaItem.albumPersistentID)
//				continue
//			}
			
			createManagedObject(for: newMediaItem)
		}
	}
	
	private func sortedInReverseTargetOrder(mediaItems mediaItemsImmutable: [MPMediaItem], isAppDatabaseEmpty: Bool) -> [MPMediaItem] {
		var mediaItems = mediaItemsImmutable
		
		// We're targeting putting new songs in this order:
		
		// If we currently have no collections:
		// - Grouped by alphabetically sorted album artist
		// - Within each album artist, grouped by alphabetically sorted album
		// - Within each album, grouped by increasing track number
		// - Within each track number (rare), sorted alphabetically
		
		// If there are any existing collections:
		// - Newer songs on top
		// - The final results will be different: we'll add songs to existing albums if possible, and add albums to existing collections if possible.
		
		if isAppDatabaseEmpty {
			mediaItems.sort() { ($0.title ?? "") < ($1.title ?? "") }
			mediaItems.sort() { $0.albumTrackNumber < $1.albumTrackNumber }
			mediaItems.sort() { 0 * $0.albumTrackNumber + $1.albumTrackNumber == 0 } // Does this do what I want? // $0 is just to satisfy the compiler… We really just want to move songs with track number 0 (unknown) to the end.
			mediaItems.sort() { ($0.albumTitle ?? "") < ($1.albumTitle ?? "") } // Albums in alphabetical order is wrong! We'll sort albums by their release dates, but we'll do it later, because it's possible that some "Album B" could have songs on it that were released both before and after some "Album A" was released as an album.
			mediaItems.sort() { ($0.albumArtist ?? "") < ($1.albumArtist ?? "") } // We'll move the "Unknown Album Artist" collection to the bottom later.
		} else {
			mediaItems.sort() { ($0.dateAdded) > ($1.dateAdded) } // There's a chance we'll have to sort songs within albums again, which wastes time. But it might be worth the code readability.
		}
		mediaItems.reverse()
		
		return mediaItems
	}
	
	private func createManagedObject(for newMediaItem: MPMediaItem) {
		coreDataManager.managedObjectContext.performAndWait {
			
			let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
			// Order doesn't matter; we're just trying to get a match.
			// TO DO: Filter the fetch request with a predicate that says "the album's persistent ID is []". Will that be faster?
			let allAlbums = coreDataManager.managedObjects(for: albumsFetchRequest) as! [Album]
			
			// 1. If we already have the Album to add the Song to, then add the Song to that Album.
			if let matchingExistingAlbum = allAlbums.first(where: { existingAlbum in
				existingAlbum.albumPersistentID == Int64(bitPattern: newMediaItem.albumPersistentID)
			})
			{
				createManagedObject(for: newMediaItem, inAlbumWithID: matchingExistingAlbum.objectID)
				
			} else { // 2. Otherwise, make the Album to add the Song to.
				createManagedObjectForNewAlbum(for: newMediaItem)
				// … and then try 1 again (risking an infinite loop).
				createManagedObject(for: newMediaItem)
			}
			
		}
	}
	
	private func createManagedObject(for newMediaItem: MPMediaItem, inAlbumWithID albumID: NSManagedObjectID) {
		coreDataManager.managedObjectContext.performAndWait {
			let album = coreDataManager.managedObjectContext.object(with: albumID) as! Album
			
			if let existingSongsInAlbum = album.contents {
				for existingSong in existingSongsInAlbum {
					(existingSong as! Song).index += 1
				}
			}
			let newSong = Song(context: coreDataManager.managedObjectContext)
			newSong.discNumber = Int64(newMediaItem.discNumber) // MPMediaItem returns non-optional Int. `0` is null or unknown.
			newSong.index = 0 //
			newSong.persistentID = Int64(bitPattern: newMediaItem.persistentID)
			newSong.trackNumber = Int64(newMediaItem.albumTrackNumber) // MPMediaItem returns non-optional Int. `0` is null or unknown.
			newSong.container = album
		}
	}
	
	// 2. Make the Album to add the Song to.
	private func createManagedObjectForNewAlbum(for newMediaItem: MPMediaItem) {
		// We should only be running this if we don't already have a managed object for the album for the song.
		coreDataManager.managedObjectContext.performAndWait {
			
			let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
			collectionsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
			let existingCollections = coreDataManager.managedObjects(for: collectionsFetchRequest)
			
			// 2.1. If we already have a Collection with a matching title, then add the Album to that Collection.
			if let existingCollectionWithMatchingTitle = existingCollections.first(where: { existingCollection in
				(existingCollection as! Collection).title == newMediaItem.albumArtist ?? Album.unknownAlbumArtistPlaceholder()
			})
			{
				let existingCollection = existingCollectionWithMatchingTitle as! Collection
				
				if let existingAlbumsInCollection = existingCollection.contents {
					for existingAlbum in existingAlbumsInCollection {
						(existingAlbum as! Album).index += 1
					}
				}
				
				let newAlbum = Album(context: coreDataManager.managedObjectContext)
				newAlbum.albumPersistentID = Int64(bitPattern: newMediaItem.albumPersistentID)
				newAlbum.index = 0
				newAlbum.container = existingCollection
				
			} else { // 2.2. Otherwise, make the Collection to add the Album to.
				createManagedObjectForNewCollection(for: newMediaItem)
				// … and then try 2 again (risking an infinite loop).
				createManagedObjectForNewAlbum(for: newMediaItem)
			}
			
		}
	}
	
	private func createManagedObjectForNewCollection(for newMediaItem: MPMediaItem) {
		// We should only be running this if we don't already have a managed object for the collection for the album for the song.
		coreDataManager.managedObjectContext.performAndWait {
			let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
			// Order doesn't matter.
			let existingCollections = coreDataManager.managedObjects(for: collectionsFetchRequest) as! [Collection]
			let newCollection = Collection(context: coreDataManager.managedObjectContext)
			
			if let defaultTitle = newMediaItem.albumArtist {
				for existingCollection in existingCollections {
					existingCollection.index += 1
				}
				
				newCollection.title = defaultTitle
				newCollection.index = 0
				
			} else {
				newCollection.title = Album.unknownAlbumArtistPlaceholder()
				newCollection.index = Int64(existingCollections.count) // Moves the collection to the bottom of the list.
			}
		}
	}
	
	// MARK: - Deleting Managed Objects
	
	func deleteManagedObjects(forSongsWith objectIDsOfSongsToDelete: [NSManagedObjectID]) { // then clean up empty albums, then clean up empty collections
		coreDataManager.managedObjectContext.performAndWait {
			for objectIDOfSongToDelete in objectIDsOfSongsToDelete {
				let songToDelete = coreDataManager.managedObjectContext.object(with: objectIDOfSongToDelete)
				coreDataManager.managedObjectContext.delete(songToDelete)
			}
		}
		
		deleteEmptyAlbums()
		deleteEmptyCollections()
	}
	
	private func deleteEmptyAlbums() {
		coreDataManager.managedObjectContext.performAndWait {
			
			let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
			// Order doesn't matter.
			// TO DO: Filter the fetch request with a predicate that says "the album has 0 contents". Will that be faster?
			let allAlbums = coreDataManager.managedObjects(for: albumsFetchRequest) as! [Album]
			
			for album in allAlbums {
				if
					let contents = album.contents,
					contents.count > 0
				{
					
				} else {
					coreDataManager.managedObjectContext.delete(album)
					// This leaves the index attributes of each album within its collection not uniform, but still in order.
				}
			}
			
		}
	}
	
	private func deleteEmptyCollections() {
		coreDataManager.managedObjectContext.performAndWait {
			
			let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
			// Order doesn't matter.
			// TO DO: Filter the fetch request with a predicate that says "the collection has 0 contents". Will that be faster?
			let allCollections = coreDataManager.managedObjects(for: collectionsFetchRequest) as! [Collection]
			
			for collection in allCollections {
				if
					let contents = collection.contents,
					contents.count > 0
				{
					
				} else {
					coreDataManager.managedObjectContext.delete(collection)
					// This leaves the index attributes of each collection not uniform, but still in order.
				}
			}
			
		}
	}
	
	// MARK: Cleanup
	
	// Only MPMediaItems have release dates, and those can't be albums.
	// An MPMediaItemCollection has a property representativeItem, but that item's release date doesn't necessarily represent the album's release date.
	// Instead, we'll estimate the albums' release dates and keep the estimates up to date.
	func recalculateReleaseDateEstimatesFor(albumsWithObjectIDs objectIDsOfAlbums: [NSManagedObjectID]) {
		coreDataManager.managedObjectContext.performAndWait {
			
			//			let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
			//			// Order doesn't matter.
			//			let allAlbums = coreDataManager.managedObjects(for: albumsFetchRequest) as! [Album]
			
			for albumID in objectIDsOfAlbums {
				// Update one album's release date estimate.
				let album = coreDataManager.managedObjectContext.object(with: albumID) as! Album
				// TO DO: Get the songs using mpMediaItemCollection() instead of Core Data?
				
				let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
				songsFetchRequest.predicate = NSPredicate(format: "container == %@", album)
				// Order doesn't matter.
				let songsInAlbum = coreDataManager.managedObjects(for: songsFetchRequest) as! [Song]
				
				album.releaseDateEstimate = nil
				
				for song in songsInAlbum {
					guard let competingEstimate = song.mpMediaItem()?.releaseDate else {
						continue
					}
					
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
	
	func reindexAlbumsWithinEachCollectionByNewestFirst(objectIDsOfCollections: [NSManagedObjectID]) {
		coreDataManager.managedObjectContext.performAndWait {
			
			for collectionID in objectIDsOfCollections {
				let collection = coreDataManager.managedObjectContext.object(with: collectionID) as! Collection
				
				let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
				albumsFetchRequest.predicate = NSPredicate(format: "container == %@", collection)
				// Order doesn't matter.
				var albumsInCollection = coreDataManager.managedObjects(for: albumsFetchRequest) as! [Album]
				let commonDate = Date()
				albumsInCollection.sort() {
					($0.releaseDateEstimate ?? commonDate) > ($1.releaseDateEstimate ?? commonDate)
				}
				for index in 0..<albumsInCollection.count {
					let album = albumsInCollection[index]
					album.index = Int64(index)
				}
			}
			
		}
	}
	
}
