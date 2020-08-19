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
		
		// Separate our saved songs into the ones that have been deleted, and the ones that have been potentially modified.
		var potentiallyModifiedMediaItems = [MPMediaItem]()
		var potentiallyModifiedSongs = [Song]()
		for queriedMediaItem in queriedMediaItems {
			if let indexOfPotentiallyModifiedSong = savedSongs.firstIndex(where: { savedSong in
				Int64(bitPattern: queriedMediaItem.persistentID) == savedSong.persistentID // We already have a record of this song. We need to check whether to update it.
			})
			{
				potentiallyModifiedMediaItems.append(queriedMediaItem)
				potentiallyModifiedSongs.append(savedSongs[indexOfPotentiallyModifiedSong])
				savedSongs.remove(at: indexOfPotentiallyModifiedSong)
			}
		}
		// savedSongs now holds the IDs of songs that have been deleted from the Apple Music library.
		let deletedSongs = savedSongs
		
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
		
//		print("New songs: \(newMediaItems.count)")
//		print("Deleted songs: \(deletedSongs.count)")
//		print("Potentially modified songs: \(potentiallyModifiedMediaItems.count)")
		
		createManagedObjects(for: newMediaItems) // Create before deleting. That way, for example, if you deleted all the songs from an album, but added other songs from that album, that album will stay in the same place in this app.
		deleteManagedObjects(for: deletedSongs)
		updateManagedObjects(for: potentiallyModifiedSongs, toMatch: potentiallyModifiedMediaItems)
		
		// Last: update album years
		recalculateReleaseDateEstimateForEachAlbum()
		
		coreDataManager.save()
	}
	
	
	// Only MPMediaItems have release dates, and those can't be albums.
	// An MPMediaItemCollection has a property representativeItem, but that item's release date doesn't necessarily represent the album's release date.
	// Instead, we'll estimate the albums' release dates and keep the estimates up to date.
	func recalculateReleaseDateEstimateForEachAlbum() {
		coreDataManager.managedObjectContext.performAndWait {
			
			let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
			// Order doesn't matter.
			let allAlbums = coreDataManager.managedObjects(for: albumsFetchRequest) as! [Album]
			
			for album in allAlbums {
				
				// Update one album's release date estimate.
				
				let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
				songsFetchRequest.predicate = NSPredicate(format: "container == %@", album)
				// Order doesn't matter.
				let allSongs = coreDataManager.managedObjects(for: songsFetchRequest) as! [Song]
				
				album.releaseDateEstimate = nil
				
				for song in allSongs {
					
					if album.releaseDateEstimate == nil {
						album.releaseDateEstimate = song.releaseDate
						
					} else {
						if
							let currentEstimate = album.releaseDateEstimate,
							let competingEstimate = song.releaseDate,
							competingEstimate > currentEstimate
						{
							album.releaseDateEstimate = competingEstimate
						}
					}
					
				}
			}
			
		}
	}
	
	
	
	// MARK: - Creating Managed Objects
	
	func createManagedObjects(for songsImmutable: [MPMediaItem]) {
		let newMediaItemsSortedInReverse = songsSortedInReverseTargetOrder(songs: songsImmutable)
		
		// Make new managed objects for the new songs, adding containers for them if necessary.
		for newMediaItem in newMediaItemsSortedInReverse {
			createManagedObject(for: newMediaItem)
		}
	}
	
	private func songsSortedInReverseTargetOrder(songs songsImmutable: [MPMediaItem]) -> [MPMediaItem] {
		var songsCopy = songsImmutable
		
		if activeLibraryItems.count == 0 {
			songsCopy.sort() { ($0.title ?? "") < ($1.title ?? "") }
			songsCopy.sort() { $0.albumTrackNumber < $1.albumTrackNumber }
			songsCopy.sort() { ($0.albumTitle ?? "") < ($1.albumTitle ?? "") }
			let commonDate = Date()
			songsCopy.sort() { ($0.releaseDate ?? commonDate) > ($1.releaseDate ?? commonDate) }
			songsCopy.sort() { ($0.albumArtist ?? "") < ($1.albumArtist ?? "") }
		} else {
			songsCopy.sort() { ($0.dateAdded) > ($1.dateAdded) }
		}
		songsCopy.reverse()
		// We're targeting putting new songs in this order:
		// - If we currently have no collections:
		// - - Grouped by alphabetically sorted album artist
		// - - Within each album artist, grouped by alphabetically sorted album
		// - - Within each album, grouped by increasing track number
		// - - Within each track number, sorted alphabetically
		// - If there are any existing collections:
		// - - Newer songs on top
		// - - The actual results will be different: songs will be added to existing albums if possible, and albums will be added to existing collections if possible.
		
		return songsCopy
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
	
	private func createManagedObject(for song: MPMediaItem, inAlbumWithID albumID: NSManagedObjectID) {
		coreDataManager.managedObjectContext.performAndWait {
			let album = coreDataManager.managedObjectContext.object(with: albumID) as! Album
			
			let newSong = Song(context: coreDataManager.managedObjectContext)
//			newSong.artist = song.artist // could be nil
			newSong.discNumber = Int64(song.discNumber) // MPMediaItem returns non-optional Int. `0` is null or unknown.
			if let songsInAlbum = album.contents { //
				for existingSong in songsInAlbum {
					(existingSong as! Song).index += 1
				}
			}
			newSong.index = 0 //
			newSong.persistentID = Int64(bitPattern: song.persistentID)
			newSong.releaseDate = song.releaseDate // could be nil
			newSong.title = song.title // could be nil
			newSong.trackNumber = Int64(song.albumTrackNumber) // MPMediaItem returns non-optional Int. `0` is null or unknown.
			newSong.container = album
		}
	}
	
	// 2. Make the Album to add the Song to.
	private func createManagedObjectForNewAlbum(for newMediaItem: MPMediaItem) {
		// We should only be running this if we don't already have a managed object for the album for the song.
		coreDataManager.managedObjectContext.performAndWait {
			
			// 2.1. If we already have a Collection with a matching title, then add the Album to that Collection.
			if let existingCollectionWithMatchingTitle = activeLibraryItems.first(where: { existingCollection in
				(existingCollection as! Collection).title == newMediaItem.albumArtist ?? Album.unknownAlbumArtistPlaceholder()
			})
			{
				let existingCollectionWithMatchingTitle = existingCollectionWithMatchingTitle as! Collection
				
				let newAlbum = Album(context: coreDataManager.managedObjectContext)
				newAlbum.albumPersistentID = Int64(bitPattern: newMediaItem.albumPersistentID)
				if let existingAlbumsInCollection = existingCollectionWithMatchingTitle.contents {
					for existingAlbum in existingAlbumsInCollection {
						(existingAlbum as! Album).index += 1
					}
				}
				newAlbum.index = 0
				newAlbum.title = newMediaItem.albumTitle // could be nil
				newAlbum.container = existingCollectionWithMatchingTitle
				
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
			let newCollection = Collection(context: coreDataManager.managedObjectContext)
			newCollection.title = newMediaItem.albumArtist ?? Album.unknownAlbumArtistPlaceholder()
			activeLibraryItems.insert(newCollection, at: 0)
		}
	}
	
	// MARK: - Deleting Managed Objects
	
	func deleteManagedObjects(for songs: [Song]) { // then clean up empty albums, then clean up empty collections
		coreDataManager.managedObjectContext.performAndWait {
			for song in songs {
				coreDataManager.managedObjectContext.delete(song)
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
				}
			}
			
		}
	}
	
	// MARK: - Update Managed Objects
	
	func updateManagedObjects(for songs: [Song], toMatch mediaItems: [MPMediaItem]) {
		
		
		
	}
	
}
