//
//  extension- merge from Apple Music library.swift
//  LavaRock
//
//  Created by h on 2020-08-15.
//

import UIKit
import CoreData
import MediaPlayer

extension CollectionsTVC {
	
	func mergeChangesFromAppleMusicLibrary() {
		
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			var queriedMediaItems = MPMediaQuery.songs().items
		else { return }
		
		let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
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
		
		createManagedObjects(for: newMediaItems)
		deleteManagedObjects(for: deletedSongs)
		updateManagedObjects(for: potentiallyModifiedSongs, toMatch: potentiallyModifiedMediaItems)
		
		// Last: update album years
		
		
		coreDataManager.save()
	}
	
	// MARK: - Creating Managed Objects
	
	func createManagedObjects(for songsImmutable: [MPMediaItem]) {
		
		let newMediaItemsSortedInReverse = songsSortedInReverseTargetOrder(songs: songsImmutable)
		
		// Make new managed objects for the new songs, adding containers for them if necessary.
		for newMediaItem in newMediaItemsSortedInReverse {
			// If we already have the album (by persistent ID) that we're adding the song to, add it to that album.
			// Otherwise, make that album:
			// - If we already have a collection with a matching title (by album artist), add it to that collection.
			// - Otherwise, make that collection.
			// - - Then make the album in that collection, like we were going to.
			// - - - Then make the song in that album, like we were going to.
			
			createManagedObject(for: newMediaItem)
		}
		
	}
	
	private func songsSortedInReverseTargetOrder(songs songsImmutable: [MPMediaItem]) -> [MPMediaItem] {
		var songsCopy = songsImmutable
		
		if activeLibraryItems.count == 0 {
			songsCopy.sort() { ($0.title ?? "") < ($1.title ?? "") }
			songsCopy.sort() { $0.albumTrackNumber < $1.albumTrackNumber }
			songsCopy.sort() { ($0.albumTitle ?? "") < ($1.albumTitle ?? "") }
			songsCopy.sort() { ($0.albumArtist ?? "") < ($1.albumArtist ?? "") }
		} else {
			songsCopy.sort() { ($0.dateAdded) > ($1.dateAdded) }
		}
		songsCopy.reverse()
		// The final order of songs added will be:
		
		
		return songsCopy
	}
	
	private func createManagedObject(for newMediaItem: MPMediaItem) {
		coreDataManager.managedObjectContext.performAndWait {
			
			let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
			// TO DO: Filter the fetch request with a predicate that says "the album's persistent ID is []". Will that be faster?
			let allAlbums = coreDataManager.managedObjects(for: albumsFetchRequest) as! [Album]
			
			// If we already have a record of the album (by albumPersistentID) that we're adding the song to.
			if let matchingExistingAlbum = allAlbums.first(where: { existingAlbum in
				existingAlbum.albumPersistentID == Int64(bitPattern: newMediaItem.albumPersistentID)
			})
			{
				createManagedObject(for: newMediaItem, inAlbumWithID: matchingExistingAlbum.objectID)
				
			} else { // Make the album to add the song to.
				createManagedObjectForNewAlbum(for: newMediaItem)
				// … and then try again (risking an infinite loop).
				createManagedObject(for: newMediaItem)
			}
			
		}
	}
	
	private func createManagedObject(for song: MPMediaItem, inAlbumWithID albumID: NSManagedObjectID) {
		coreDataManager.managedObjectContext.performAndWait {
			let album = coreDataManager.managedObjectContext.object(with: albumID) as! Album
			
			let newSong = Song(context: coreDataManager.managedObjectContext)
			newSong.artist = song.artist
			newSong.discNumber = Int64(song.discNumber)
			newSong.index = 0 //
			if let songsInAlbum = album.contents {
				for existingSong in songsInAlbum {
					(existingSong as! Song).index += 1
				}
			}
			newSong.persistentID = Int64(bitPattern: song.persistentID)
			newSong.title = song.title
			newSong.trackNumber = Int64(song.albumTrackNumber)
			newSong.container = album
		}
	}
	
	private func createManagedObjectForNewAlbum(for newMediaItem: MPMediaItem) {
		// We should only be running this if we don't already have a managed object for the album for the song.
		coreDataManager.managedObjectContext.performAndWait {
			
			// If we already have a collection with a matching title (by album artist) that we should add the album to.
			if let existingCollectionWithMatchingTitle = activeLibraryItems.first(where: { existingCollection in
				(existingCollection as! Collection).title == newMediaItem.albumArtist
			})
			{
				let existingCollectionWithMatchingTitle = existingCollectionWithMatchingTitle as! Collection
				
				let newAlbum = Album(context: coreDataManager.managedObjectContext)
				newAlbum.albumArtist = newMediaItem.albumArtist
				newAlbum.albumPersistentID = Int64(bitPattern: newMediaItem.albumPersistentID)
				newAlbum.index = 0
				if let existingAlbumsInCollection = existingCollectionWithMatchingTitle.contents {
					for existingAlbum in existingAlbumsInCollection {
						(existingAlbum as! Album).index += 1
					}
				}
				newAlbum.title = newMediaItem.albumTitle
//				newAlbum.year =
				newAlbum.container = existingCollectionWithMatchingTitle
				
			} else { // Make the collection to add the album to.
				createManagedObjectForNewCollection(for: newMediaItem)
				// … and then try again (risking an infinite loop).
				createManagedObjectForNewAlbum(for: newMediaItem)
			}
			
		}
	}
	
	private func createManagedObjectForNewCollection(for newMediaItem: MPMediaItem) {
		// We should only be running this if we don't already have a managed object for the collection for the album for the song.
		coreDataManager.managedObjectContext.performAndWait {
			let newCollection = Collection(context: coreDataManager.managedObjectContext)
			newCollection.title = newMediaItem.albumArtist ?? ""
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
