//
//  Merge from Apple Music Library.swift
//  LavaRock
//
//  Created by h on 2020-08-15.
//

import UIKit
import CoreData
import MediaPlayer

extension Notification.Name {
	static let LRDidMergeChangesFromAppleMusicLibrary = Notification.Name("MediaPlayerManager has merged changes from the Apple Music library. Objects that depend on either of those should observe this notification, and respond appropriately at this point.") // Merged into where? The persistent store and/or which managed object context?
}

extension MediaPlayerManager {
	
	// This is where the magic happens. This is the engine that keeps our data structures matched up with the Apple Music library.
	func mergeChangesFromAppleMusicLibrary() {
		
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			var queriedMediaItems = MPMediaQuery.songs().items
		else { return }
		
//		let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
//		managedObjectContext.parent = mainManagedObjectContext
//
//		managedObjectContext.performAndWait {
		
		let managedObjectContext = mainManagedObjectContext
		
		let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
		// Order doesn't matter, because this will end up being the array of songs to be deleted.
		let savedSongs = managedObjectContext.objectsFetched(for: songsFetchRequest) as! [Song]
		let wasAppDatabaseEmptyBeforeMerge = savedSongs.count == 0
		
		// Find out which of our saved Songs we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the MPMediaItems we haven't seen before. We'll make new managed objects for them.
		var potentiallyModifiedSongObjectIDs = [NSManagedObjectID]()
		var potentiallyModifiedMediaItems = [MPMediaItem]()
		var objectIDsOfSongsToDelete = [NSManagedObjectID]()
		for savedSong in savedSongs {
			if let indexOfPotentiallyModifiedMediaItem = queriedMediaItems.firstIndex(where: { queriedMediaItem in
				savedSong.persistentID == Int64(bitPattern: queriedMediaItem.persistentID)
			}) {
				potentiallyModifiedSongObjectIDs.append(savedSong.objectID)
				let potentiallyModifiedMediaItem = queriedMediaItems[indexOfPotentiallyModifiedMediaItem]
				potentiallyModifiedMediaItems.append(potentiallyModifiedMediaItem)
				queriedMediaItems.remove(at: indexOfPotentiallyModifiedMediaItem)
				
			} else {
				objectIDsOfSongsToDelete.append(savedSong.objectID)
			}
		}
		// queriedMediaItems now holds the MPMediaItems that we don't have records of.
		let newMediaItems = queriedMediaItems
		
		//		print("")
		//		print("Potentially modified songs: \(potentiallyModifiedMediaItems.count)")
		//		for item in potentiallyModifiedMediaItems {
		//			print("")
		//			print("\(String(describing: item.albumTitle)): \(item.albumPersistentID)")
		//			print("\(String(describing: item.title)): \(item.persistentID)")
		//		}
		//		print("")
		//		print("Added songs: \(newMediaItems.count)")
		//		for item in newMediaItems {
		//			print("")
		//			print("\(String(describing: item.albumTitle)): \(item.albumPersistentID)")
		//			print("\(String(describing: item.title)): \(item.persistentID)")
		//		}
		//		print("")
		//		print("Deleted songs: \(objectIDsOfSongsToDelete.count)")
		
		updateManagedObjects( // Update before creating and deleting, so that we can put new songs above modified songs (easily).
			// This might make new albums, but not new collections.
			// Also, this might leave behind "hollow" updated albums, which have no songs in them because they were all moved to other albums; but we won't delete those "hollow" albums, so that if the user also added other songs to that "hollow" album, we can keep that album in the same place, instead of re-adding it to the top.
			forSongsWith: potentiallyModifiedSongObjectIDs,
			toMatch: potentiallyModifiedMediaItems,
			in: managedObjectContext)
		createManagedObjects( // Create before deleting, because deleting also cleans up empty albums and collections, and we don't want to do that yet, because of what we mentioned above.
			// This might make new albums, and if it does, it might make new collections.
			for: newMediaItems,
			isAppDatabaseEmpty: wasAppDatabaseEmptyBeforeMerge,
			in: managedObjectContext)
		deleteManagedObjects(
			forSongsWith: objectIDsOfSongsToDelete,
			in: managedObjectContext)
		
		// Then, some cleanup.
		
		var collectionIDs = [NSManagedObjectID]()
		let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
		// Order doesn't matter.
		let allCollections = managedObjectContext.objectsFetched(for: collectionsFetchRequest) as! [Collection]
		for collection in allCollections {
			collectionIDs.append(collection.objectID)
		}
		
		var albumIDs = [NSManagedObjectID]()
		let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
		// Order doesn't matter.
		let allAlbums = managedObjectContext.objectsFetched(for: albumsFetchRequest) as! [Album]
		for album in allAlbums {
			albumIDs.append(album.objectID)
		}
		
		//			var songIDs = [NSManagedObjectID]()
		//			let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
		//			// Order doesn't matter.
		//			let allSongs = coreDataManager.objectsFetched(for: songsFetchRequest) as! [Song]
		//			for song in allSongs {
		//				songIDs.append(song.objectID)
		//			}
		
		recalculateReleaseDateEstimatesFor(
			albumsWithObjectIDs: albumIDs,
			in: managedObjectContext)
		
		if wasAppDatabaseEmptyBeforeMerge {
			
			//						inCollectionsWith collectionIDs: [NSManagedObjectID]
			// TO DO:
			// Take out the fetch above for albums.
			// New modus operandi: within each collection, recalculate the release date estimates of all the albums, then sort them from newest to oldest by those new estimates.
			
			//			for collectionID in collectionIDs {
			//
			//			}
			
			reindexAlbumsWithinEachCollectionByNewestFirst(
				objectIDsOfCollections: collectionIDs,
				in: managedObjectContext)
		}
		
		//		}
		
		managedObjectContext.tryToSave()
		DispatchQueue.main.async {
//			managedObjectContext.parent!.tryToSave()
			NotificationCenter.default.post( // Notifications are dealt with on the thread you post them in, so post this notification on the main thread.
				Notification(name: Notification.Name.LRDidMergeChangesFromAppleMusicLibrary)
			)
		}
	}
	
	// MARK: - Update Managed Objects
	
	private func updateManagedObjects(
		forSongsWith objectIDsOfSongsToUpdate: [NSManagedObjectID],
		toMatch mediaItems: [MPMediaItem],
		in managedObjectContext: NSManagedObjectContext
	) {
		// Here, you can update any stored attributes on each song. But unless we have to, it's best to not store that data in the first place, because we'll have to manually keep up to date.
		
		updateRelationshipsBetweenAlbumsAndSongs(
			with: objectIDsOfSongsToUpdate,
			toMatch: mediaItems,
			in: managedObjectContext)
	}
	
	private func updateRelationshipsBetweenAlbumsAndSongs(
		with songObjectIDs: [NSManagedObjectID],
		toMatch mediaItems: [MPMediaItem],
		in managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			
			var potentiallyOutdatedSongs = [Song]()
			for songID in songObjectIDs {
				let song = managedObjectContext.object(with: songID) as! Song
				potentiallyOutdatedSongs.append(song)
			}
			
			potentiallyOutdatedSongs.sort() { $0.index < $1.index }
			potentiallyOutdatedSongs.sort() { $0.container!.index < $1.container!.index }
			potentiallyOutdatedSongs.sort() { $0.container!.container!.index < $1.container!.container!.index }
//			print("")
//			for song in potentiallyOutdatedSongs {
//				print(song.titleFormattedOrPlaceholder())
//				print("Container index: \(song.container!.container!.index), album index: \(song.container!.index), song index: \(song.index)")
//			}
			
			var knownAlbumPersistentIDs = [Int64]()
			var existingAlbums = [Album]()
			for song in potentiallyOutdatedSongs {
				knownAlbumPersistentIDs.append(song.container!.albumPersistentID)
				existingAlbums.append(song.container!)
			}
			
			for song in potentiallyOutdatedSongs.reversed() {
				
				let knownAlbumPersistentID = song.container!.albumPersistentID
				let newAlbumPersistentID = song.mpMediaItem()!.albumPersistentID
//				print("")
//				print("Checking album status of \(song.titleFormattedOrPlaceholder()).")
//				print("Previously known albumPersistentID: \(UInt64(bitPattern: knownAlbumPersistentID))")
//				print("New albumPersistentID: \(newAlbumPersistentID)")
				
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
	
	// Make new managed objects for the new songs, adding containers for them if necessary.
	private func createManagedObjects(
		for newMediaItems: [MPMediaItem],
		isAppDatabaseEmpty: Bool,
		in managedObjectContext: NSManagedObjectContext
	) {
		let newMediaItemsSortedInReverse = sortedInReverseTargetOrder(
			mediaItems: newMediaItems,
			isAppDatabaseEmpty: isAppDatabaseEmpty)
		
		for newMediaItem in newMediaItemsSortedInReverse {
			
			// Trying to filter out music videos (and giving up on it)
//			guard newMediaItem.mediaType != .musicVideo else { // Apparently music videos don't match MPMediaType.musicVideo
//			guard newMediaItem.mediaType != .anyVideo else { // This doesn't work either
//			if newMediaItem.mediaType.rawValue == UInt(2049) { // This works, but seems fragile
//				print(newMediaItem.albumTitle)
//				print(newMediaItem.title)
//				print(newMediaItem.albumPersistentID)
//				print(newMediaItem.persistentID)
//				continue
//			}
			
			createManagedObject(
				for: newMediaItem,
				in: managedObjectContext)
		}
	}
	
	private func sortedInReverseTargetOrder(mediaItems mediaItemsImmutable: [MPMediaItem], isAppDatabaseEmpty: Bool) -> [MPMediaItem] {
		var mediaItems = mediaItemsImmutable
		
		// We're targeting putting new songs in this order:
		
		// If we currently have no collections:
		// - Grouped by alphabetically sorted album artist
		// - Within each album artist, grouped by album, from newest to oldest
		// - Within each album, grouped by increasing disc number
		// - Within each disc, grouped by increasing track number, with "unknown" at the end
		// - Within each track number (rare), sorted alphabetically
		
		// If there are any existing collections:
		// - Newer songs on top
		// The final results will be different: we'll add songs to existing albums if possible, and add albums to existing collections if possible.
		
		if isAppDatabaseEmpty {
			mediaItems.sort() { ($0.title ?? "") < ($1.title ?? "") }
			mediaItems.sort() { $0.albumTrackNumber < $1.albumTrackNumber }
			mediaItems.sort() { $1.albumTrackNumber == 0 }
			mediaItems.sort() { $0.discNumber < $1.discNumber }
			// As of iOS 14.0 beta 5, MediaPlayer reports unknown disc numbers as 1, so there's no need to move disc 0 to the end.
			mediaItems.sort() { ($0.albumTitle ?? "") < ($1.albumTitle ?? "") }
			// Albums in alphabetical order is wrong! We'll sort albums by their release dates, but we'll do it later, because we have to keep songs grouped together by album, and some "Album B" could have songs on it that were originally released both before and after the day some earlier "Album A" was released as an album.
			mediaItems.sort() { ($0.albumArtist ?? "") < ($1.albumArtist ?? "") }
			let unknownAlbumArtistPlaceholder = Album.unknownAlbumArtistPlaceholder()
			mediaItems.sort() { ($1.albumArtist ?? unknownAlbumArtistPlaceholder) == unknownAlbumArtistPlaceholder }
		} else {
			mediaItems.sort() { ($0.dateAdded) > ($1.dateAdded) } // There's a chance we'll have to sort songs within albums again, which will take more time.
		}
		mediaItems.reverse()
		
		return mediaItems
	}
	
	private func createManagedObject(
		for newMediaItem: MPMediaItem,
		in managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			
			let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
			// Order doesn't matter; we're just trying to get a match.
			// TO DO: Filter the fetch request with a predicate that says "the album's persistent ID is []". Will that be faster?
			let allAlbums = managedObjectContext.objectsFetched(for: albumsFetchRequest) as! [Album]
			
			// 1. If we already have the Album to add the Song to, then add the Song to that Album.
			if let matchingExistingAlbum = allAlbums.first(where: { existingAlbum in
				existingAlbum.albumPersistentID == Int64(bitPattern: newMediaItem.albumPersistentID)
			}) {
				createManagedObject(
					for: newMediaItem,
					inAlbumWithID: matchingExistingAlbum.objectID,
					in: managedObjectContext)
				
			} else { // 2. Otherwise, make the Album to add the Song to.
				createManagedObjectForNewAlbum(
					for: newMediaItem,
					in: managedObjectContext)
				// … and then try 1 again (risking an infinite loop).
				createManagedObject(
					for: newMediaItem,
					in: managedObjectContext)
			}
			
		}
	}
	
	private func createManagedObject(
		for newMediaItem: MPMediaItem,
		inAlbumWithID albumID: NSManagedObjectID,
		in managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			let album = managedObjectContext.object(with: albumID) as! Album
			
			if let existingSongsInAlbum = album.contents {
				for existingSong in existingSongsInAlbum {
					(existingSong as! Song).index += 1
				}
			}
			let newSong = Song(context: managedObjectContext)
			newSong.index = 0 //
			newSong.persistentID = Int64(bitPattern: newMediaItem.persistentID)
			newSong.container = album
		}
	}
	
	// 2. Make the Album to add the Song to.
	private func createManagedObjectForNewAlbum(
		for newMediaItem: MPMediaItem,
		in managedObjectContext: NSManagedObjectContext
	) {
		// We should only be running this if we don't already have a managed object for the album for the song.
		managedObjectContext.performAndWait {
			
			let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
			collectionsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
			// Order matters, because we're going to (try to) add the album to the *first* collection with a matching title.
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
				
			} else { // 2.2. Otherwise, make the Collection to add the Album to.
				createManagedObjectForNewCollection(
					for: newMediaItem,
					in: managedObjectContext)
				// … and then try 2 again (risking an infinite loop).
				createManagedObjectForNewAlbum(
					for: newMediaItem,
					in: managedObjectContext)
			}
			
		}
	}
	
	private func createManagedObjectForNewCollection(
		for newMediaItem: MPMediaItem,
		in managedObjectContext: NSManagedObjectContext
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
		forSongsWith objectIDsOfSongsToDelete: [NSManagedObjectID],
		in managedObjectContext: NSManagedObjectContext
	) { // then clean up empty albums, then clean up empty collections
		managedObjectContext.performAndWait {
			for objectIDOfSongToDelete in objectIDsOfSongsToDelete {
				let songToDelete = managedObjectContext.object(with: objectIDOfSongToDelete)
				managedObjectContext.delete(songToDelete)
			}
		}
		
		deleteEmptyAlbums(in: managedObjectContext)
		deleteEmptyCollections(in: managedObjectContext)
	}
	
	private func deleteEmptyAlbums(
		in managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			
			let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
			// Order doesn't matter.
			// TO DO: Filter the fetch request with a predicate that says "the album has 0 contents". Will that be faster?
			let allAlbums = managedObjectContext.objectsFetched(for: albumsFetchRequest) as! [Album]
			
			for album in allAlbums {
				if
					let contents = album.contents,
					contents.count > 0
				{
					
				} else {
					managedObjectContext.delete(album)
					// This leaves the index attributes of each album within its collection not uniform, but still in order.
				}
			}
			
		}
	}
	
	private func deleteEmptyCollections(
		in managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			
			let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
			// Order doesn't matter.
			// TO DO: Filter the fetch request with a predicate that says "the collection has 0 contents". Will that be faster?
			let allCollections = managedObjectContext.objectsFetched(for: collectionsFetchRequest) as! [Collection]
			
			for collection in allCollections {
				if
					let contents = collection.contents,
					contents.count > 0
				{
					
				} else {
					managedObjectContext.delete(collection)
					// This leaves the index attributes of each collection not uniform, but still in order.
				}
			}
			
		}
	}
	
	// MARK: - Cleanup
	
	// Only MPMediaItems have release dates, and those can't be albums.
	// An MPMediaItemCollection has a property representativeItem, but that item's release date doesn't necessarily represent the album's release date.
	// Instead, we'll estimate the albums' release dates and keep the estimates up to date.
	private func recalculateReleaseDateEstimatesFor(
		albumsWithObjectIDs objectIDsOfAlbums: [NSManagedObjectID],
		in managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			
			for albumID in objectIDsOfAlbums {
				// Update one album's release date estimate.
				let album = managedObjectContext.object(with: albumID) as! Album
				// TO DO: Get the songs using mpMediaItemCollection() instead of Core Data?
				
				let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
				songsFetchRequest.predicate = NSPredicate(format: "container == %@", album)
				// Order doesn't matter.
				let songsInAlbum = managedObjectContext.objectsFetched(for: songsFetchRequest) as! [Song]
				
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
	
	private func reindexAlbumsWithinEachCollectionByNewestFirst(
		objectIDsOfCollections: [NSManagedObjectID],
		in managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
			
			for collectionID in objectIDsOfCollections {
				let collection = managedObjectContext.object(with: collectionID) as! Collection
				
				let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
				albumsFetchRequest.predicate = NSPredicate(format: "container == %@", collection)
				// Order doesn't matter.
				var albumsInCollection = managedObjectContext.objectsFetched(for: albumsFetchRequest) as! [Album]
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
