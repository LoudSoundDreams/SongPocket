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
		
		var songsCopy = songsImmutable
		if activeLibraryItems.count == 0 {
			songsCopy.sort() { ($0.title ?? "") < ($1.title ?? "") }
			songsCopy.sort() { $0.albumTrackNumber < $1.albumTrackNumber }
			songsCopy.sort() { ($0.albumTitle ?? "") < ($1.albumTitle ?? "") }
			songsCopy.sort() { ($0.albumArtist ?? "") < ($1.albumArtist ?? "") }
		} else {
			songsCopy.sort() { ($0.dateAdded) > ($1.dateAdded) }
		}
		
		// Make new managed objects for the new songs, adding containers for them if necessary.
		for newMediaItem in songsCopy.reversed() {
			// The final order of songs added will be:
			
			
			if let existingCollectionWithMatchingTitle = activeLibraryItems.first(where: { (collection) in
				(collection as! Collection).title == newMediaItem.albumArtist
			})
			{
				createManagedObject(for: newMediaItem, inCollection: existingCollectionWithMatchingTitle as! Collection) // Batch these? If so, watch the order!
				
			} else { // There is no existing collection whose title matches the album artist of the new media item.
				coreDataManager.managedObjectContext.performAndWait {
					let newCollection = Collection(context: coreDataManager.managedObjectContext)
					newCollection.title = newMediaItem.albumArtist ?? ""
					activeLibraryItems.insert(newCollection, at: 0)
				}
				// … and then try again (with force!).
				let existingCollectionWithMatchingTitle = activeLibraryItems.first(where: { (collection) in
					(collection as! Collection).title == newMediaItem.albumArtist
				})!
				createManagedObject(for: newMediaItem, inCollection: existingCollectionWithMatchingTitle as! Collection) // Batch these?
			}
		}
		
	}
	
	private func createManagedObject(for song: MPMediaItem, inCollection collection: Collection) {
		
		let albumsInCollection = collection.contents
		
		// If the collection already contains the album that the song belongs to.
		if let existingAlbum = albumsInCollection?.first(where: { (album) in
			(album as! Album).albumPersistentID == Int64(bitPattern: song.albumPersistentID)
		})
		{
			createManagedObject(for: song, inAlbum: existingAlbum as! Album)
			
		} else { // Make the album to add the song to.
			coreDataManager.managedObjectContext.performAndWait {
				let newAlbum = Album(context: coreDataManager.managedObjectContext)
				newAlbum.albumArtist = song.albumArtist
				newAlbum.albumPersistentID = Int64(bitPattern: song.albumPersistentID)
				newAlbum.index = 0
				if let albumsInCollection = albumsInCollection {
					for album in albumsInCollection {
						(album as! Album).index += 1
					}
				}
				newAlbum.title = song.albumTitle
//				newAlbum.year =
				newAlbum.container = collection
				createManagedObject(for: song, inAlbum: newAlbum)
			}
		}
		
	}
	
	private func createManagedObject(for song: MPMediaItem, inAlbum album: Album) {
		coreDataManager.managedObjectContext.performAndWait {
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
	
	// MARK: - Deleting Managed Objects
	
	func deleteManagedObjects(for songs: [Song]) { // then clean up empty albums, then clean up empty collections
		coreDataManager.managedObjectContext.performAndWait {
			for song in songs {
				coreDataManager.managedObjectContext.delete(song)
			}
			
			deleteEmptyAlbums()
			deleteEmptyCollections()
		}
	}
	
	private func deleteEmptyAlbums() {
		let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
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
	
	private func deleteEmptyCollections() {
		let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
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
	
	// MARK: - Update Managed Objects
	
	func updateManagedObjects(for songs: [Song], toMatch mediaItems: [MPMediaItem]) {
		
		
		
	}
	
}
