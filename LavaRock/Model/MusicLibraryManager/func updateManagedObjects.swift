//
//  func updateManagedObjects.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import MediaPlayer
import OSLog

extension MusicLibraryManager {
	
	private static let logForUpdateObjects = OSLog(
		subsystem: subsystemName,
		category: "1. Update Managed Objects")
	
	final func updateManagedObjects(
		for songs: [Song],
		toMatch mediaItems: Set<MPMediaItem>
	) {
		os_signpost(
			.begin,
			log: Self.logForImportChanges,
			name: "1. Update Managed Objects")
		defer {
			os_signpost(
				.end,
				log: Self.logForImportChanges,
				name: "1. Update Managed Objects")
		}
		
		// Here, you can update any attributes on each Song. But it's best to not store data on each Song in the first place unless we have to, because we'll have to manually keep it up to date.
		
		updateRelationshipsBetweenAlbumsAndSongs(
			songs: songs,
			toMatch: mediaItems)
	}
	
	private func updateRelationshipsBetweenAlbumsAndSongs(
		songs potentiallyOutdatedSongs: [Song], // Don't use a Set, because we sort this.
		toMatch freshMediaItems: Set<MPMediaItem> // Use a set, because we search through this.
	) {
		var potentiallyOutdatedSongs = potentiallyOutdatedSongs
		
		// Group and sort them by Collection, Album, and Song order.
		os_signpost(
			.begin,
			log: Self.logForUpdateObjects,
			name: "Initial sort")
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
		os_signpost(
			.end,
			log: Self.logForUpdateObjects,
			name: "Initial sort")
		
		var knownAlbumPersistentIDs = Set<Int64>()
		var existingAlbums = [Album]()
		for song in potentiallyOutdatedSongs {
			knownAlbumPersistentIDs.insert(song.container!.albumPersistentID)
			existingAlbums.append(song.container!)
		}
		var freshMediaItemsCopy = freshMediaItems
		for song in potentiallyOutdatedSongs.reversed() {
			os_signpost(
				.begin,
				log: Self.logForUpdateObjects,
				name: "Update which Album is associated with one Song")
			defer {
				os_signpost(
					.end,
					log: Self.logForUpdateObjects,
					name: "Update which Album is associated with one Song")
			}
			
			let knownAlbumPersistentID = song.container!.albumPersistentID
			
			// Get this Song's fresh albumPersistentID.
			// Don't use song.mpMediaItem() for every Song; it's way too slow.
			os_signpost(
				.begin,
				log: Self.logForUpdateObjects,
				name: "Match a fresh MPMediaItem to find this Song's new albumPersistentID")
			let indexOfMatchingFreshMediaItem = freshMediaItemsCopy.firstIndex(where: { freshMediaItem in
				Int64(bitPattern: freshMediaItem.persistentID) == song.persistentID
			})!
			let matchingFreshMediaItem = freshMediaItemsCopy[indexOfMatchingFreshMediaItem]
			let freshAlbumPersistentID_asInt64 = Int64(bitPattern: matchingFreshMediaItem.albumPersistentID)
			// Speed things up as we go, by reducing the number of freshMediaItems to go through.
			freshMediaItemsCopy.remove(at: indexOfMatchingFreshMediaItem)
			os_signpost(
				.end,
				log: Self.logForUpdateObjects,
				name: "Match a fresh MPMediaItem to find this Song's new albumPersistentID")
			
			// If this Song's albumPersistentID has stayed the same, move on to the next one.
			guard freshAlbumPersistentID_asInt64 != knownAlbumPersistentID else { continue }
			
			// This Song's albumPersistentID has changed.
			
			if !knownAlbumPersistentIDs.contains(freshAlbumPersistentID_asInt64) { // If we don't already have an Album with this albumPersistentID …
				
				// Make a note of this albumPersistentID.
				knownAlbumPersistentIDs.insert(freshAlbumPersistentID_asInt64)
				
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
				newAlbum.albumPersistentID = freshAlbumPersistentID_asInt64
				// We'll set releaseDateEstimate later.
				
				// Put the song into the new Album.
				song.index = 0
				song.container = newAlbum
				
			} else { // This Song's albumPersistentID has changed, but we already have an Album for it.
				knownAlbumPersistentIDs.insert(freshAlbumPersistentID_asInt64)
				// Get the Album.
				let existingAlbum = existingAlbums.first(where: { existingAlbum in
					existingAlbum.albumPersistentID == freshAlbumPersistentID_asInt64
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
