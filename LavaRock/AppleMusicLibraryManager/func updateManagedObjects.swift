//
//  func updateManagedObjects.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import MediaPlayer
import OSLog

extension AppleMusicLibraryManager {
	
	private static let updateManagedObjectsLog = OSLog(
		subsystem: subsystemForOSLog,
		category: "1. Update Managed Objects")
	
	final func updateManagedObjects(
		forSongsWith songIDs: [NSManagedObjectID],
		toMatch mediaItems: [MPMediaItem]
	) {
		os_signpost(.begin, log: Self.updateManagedObjectsLog, name: "Subroutine")
		defer {
			os_signpost(.end, log: Self.updateManagedObjectsLog, name: "Subroutine")
		}
		
		// Here, you can update any attributes on each Song. But it's best to not store data on each Song in the first place unless we have to, because we'll have to manually keep it up to date.
		
		updateRelationshipsBetweenAlbumsAndSongs(
			with: songIDs,
			toMatch: mediaItems)
	}
	
	private func updateRelationshipsBetweenAlbumsAndSongs(
		with songIDs: [NSManagedObjectID],
		toMatch freshMediaItems: [MPMediaItem]
	) {
		// Get all the Songs we might need to update.
		var potentiallyOutdatedSongs = [Song]()
		for songID in songIDs {
			let song = managedObjectContext.object(with: songID) as! Song
			potentiallyOutdatedSongs.append(song)
		}
		
		// Group and sort them by Collection, Album, and Song order.
		os_signpost(.begin, log: Self.updateManagedObjectsLog, name: "Initial Sort")
		potentiallyOutdatedSongs.sort { $0.index < $1.index }
		potentiallyOutdatedSongs.sort { $0.container!.index < $1.container!.index }
		potentiallyOutdatedSongs.sort { $0.container!.container!.index < $1.container!.container!.index }
		/*
		print("")
		for song in potentiallyOutdatedSongs {
		print(song.titleFormattedOrPlaceholder())
		print("Collection \(song.container!.container!.index), Album \(song.container!.index), Song \(song.index)")
		}
		*/
		os_signpost(.end, log: Self.updateManagedObjectsLog, name: "Initial Sort")
		
		var knownAlbumPersistentIDs = Set<Int64>()
		var existingAlbums = [Album]()
		for song in potentiallyOutdatedSongs {
			knownAlbumPersistentIDs.insert(song.container!.albumPersistentID)
			existingAlbums.append(song.container!)
		}
		var freshMediaItemsCopy = Set(freshMediaItems)
		for song in potentiallyOutdatedSongs.reversed() {
			os_signpost(.begin, log: Self.updateManagedObjectsLog, name: "Update which Album is associated with one Song")
			defer {
				os_signpost(.end, log: Self.updateManagedObjectsLog, name: "Update which Album is associated with one Song")
			}
			
			let knownAlbumPersistentID = song.container!.albumPersistentID
			
			// Get this Song's fresh albumPersistentID.
			// Don't use song.mpMediaItem() for every Song; it's way too slow.
			os_signpost(.begin, log: Self.updateManagedObjectsLog, name: "Match a fresh MPMediaItem to find this Song's new albumPersistentID")
			let indexOfMatchingFreshMediaItem = freshMediaItemsCopy.firstIndex(where: { freshMediaItem in
				freshMediaItem.persistentID == song.persistentID
			})!
			let matchingFreshMediaItem = freshMediaItemsCopy[indexOfMatchingFreshMediaItem]
			let freshAlbumPersistentID = matchingFreshMediaItem.albumPersistentID
			// Speed things up as we go, by reducing the number of freshMediaItems to go through.
			freshMediaItemsCopy.remove(at: indexOfMatchingFreshMediaItem)
			os_signpost(.end, log: Self.updateManagedObjectsLog, name: "Match a fresh MPMediaItem to find this Song's new albumPersistentID")
			
			// If this Song's albumPersistentID has stayed the same, move on to the next one.
			guard Int64(bitPattern: freshAlbumPersistentID) != knownAlbumPersistentID else { continue }
			
			// This Song's albumPersistentID has changed.
			
			if !knownAlbumPersistentIDs.contains(Int64(bitPattern: freshAlbumPersistentID)) { // If we don't already have an Album with this albumPersistentID …
				
				// Make a note of this albumPersistentID.
				knownAlbumPersistentIDs.insert(Int64(bitPattern: freshAlbumPersistentID))
				
				// Make a new Album.
				let newAlbum = Album(context: managedObjectContext)
				
				// Make a note of the new Album.
				existingAlbums.insert(newAlbum, at: 0)
				
				// Set the Album's attributes.
				newAlbum.container = song.container!.container!
				for album in newAlbum.container!.contents! { // For each Album in the same Collection as the new Album
					(album as! Album).index += 1
				}
				newAlbum.index = 0
				newAlbum.albumPersistentID = Int64(bitPattern: freshAlbumPersistentID)
				// We'll set releaseDateEstimate later.
				
				// Put the song into the new Album.
				song.index = 0
				song.container = newAlbum
				
			} else { // This Song's albumPersistentID has changed, but we already have an Album for it.
				knownAlbumPersistentIDs.insert(Int64(bitPattern: freshAlbumPersistentID))
				// Get the Album.
				let existingAlbum = existingAlbums.first(where: { existingAlbum in
					existingAlbum.albumPersistentID == Int64(bitPattern: freshAlbumPersistentID)
				})!
				
				// Add the song to the Album.
				for song in existingAlbum.contents! { // For each Song in the same Album as the current Song
					(song as! Song).index += 1
				}
				song.index = 0
				song.container = existingAlbum
			}
		}
		
		// We'll delete empty Albums (and Collections) later.
	}
	
}
