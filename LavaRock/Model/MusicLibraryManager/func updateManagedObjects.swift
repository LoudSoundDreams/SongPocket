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
	
	final func updateManagedObjects(
		for songs: [Song],
		toMatch mediaItems: Set<MPMediaItem>
	) {
		os_signpost(.begin, log: importLog, name: "2. Update Managed Objects")
		defer {
			os_signpost(.end, log: importLog, name: "2. Update Managed Objects")
		}
		
		// Here, you can update any attributes on each Song. But it's best to not store data on each Song in the first place unless we have to, because we'll have to manually keep it up to date.
		
		os_signpost(.begin, log: updateLog, name: "Update all Album–Song relationships")
		updateRelationshipsBetweenAlbumsAndSongs(
			songs: songs,
			toMatch: mediaItems)
		os_signpost(.end, log: updateLog, name: "Update all Album–Song relationships")
	}
	
	private func updateRelationshipsBetweenAlbumsAndSongs(
		songs potentiallyOutdatedSongs: [Song], // Don't use a Set, because we sort this.
		toMatch freshMediaItems: Set<MPMediaItem> // Use a Set, because we search through this.
	) {
		// Sort the existing Songs by the order they appeared in in the app.
		os_signpost(.begin, log: updateLog, name: "Initial sort")
		let sortedSongs = potentiallyOutdatedSongs.sorted { leftSong, rightSong in
			// Checking Song index first and Collection index last is slightly faster than the reverse.
			guard leftSong.index == rightSong.index else {
				return leftSong.index < rightSong.index
			}
			
			let leftAlbum = leftSong.container!
			let rightAlbum = rightSong.container!
			guard leftAlbum.index == rightAlbum.index else {
				return leftAlbum.index < rightAlbum.index
			}
			
			let leftCollection = leftAlbum.container!
			let rightCollection = rightAlbum.container!
			return leftCollection.index < rightCollection.index
		}
		os_signpost(.end, log: updateLog, name: "Initial sort")
		
		os_signpost(.begin, log: updateLog, name: "Initialize updatedMediaItems")
		let mediaItemTuples = freshMediaItems.map { mediaItem in
			(Int64(bitPattern: mediaItem.persistentID),
			mediaItem)
		}
		let mediaItems_byInt64 = Dictionary(uniqueKeysWithValues: mediaItemTuples)
		os_signpost(.end, log: updateLog, name: "Initialize updatedMediaItems")
		
		os_signpost(.begin, log: updateLog, name: "Initialize existingAlbumsByAlbumPersistentID")
		var existingAlbums_byInt64 = [Int64: Album]()
		sortedSongs.forEach {
			let oldAlbum = $0.container!
			existingAlbums_byInt64[oldAlbum.albumPersistentID] = oldAlbum
		}
		os_signpost(.end, log: updateLog, name: "Initialize existingAlbumsByAlbumPersistentID")
		
		sortedSongs.reversed().forEach { song in
			os_signpost(.begin, log: updateLog, name: "Update one Album–Song relationship")
			defer {
				os_signpost(.end, log: updateLog, name: "Update one Album–Song relationship")
			}
			
			// Get this Song's fresh albumPersistentID.
			os_signpost(.begin, log: updateLog, name: "Get one Song's fresh albumPersistentID")
			let mediaItem = mediaItems_byInt64[song.persistentID]!
			let newAlbumPersistentID_asInt64 = Int64(bitPattern: mediaItem.albumPersistentID)
			os_signpost(.end, log: updateLog, name: "Get one Song's fresh albumPersistentID")
			
			// If this Song's albumPersistentID has stayed the same, move on to the next one.
			let oldAlbumPersistentID = song.container!.albumPersistentID
			guard
				newAlbumPersistentID_asInt64 != oldAlbumPersistentID
			else { return }
			
			// This Song's albumPersistentID has changed.
			// If we already have a matching Album to move the Song to …
			if let existingAlbum = existingAlbums_byInt64[
				newAlbumPersistentID_asInt64
			] {
				// … then move the Song to that Album.
				os_signpost(.begin, log: updateLog, name: "Move a Song to an existing Album")
				existingAlbum.songs(sorted: false).forEach { $0.index += 1 }
				
				song.index = 0
				song.container = existingAlbum
				os_signpost(.end, log: updateLog, name: "Move a Song to an existing Album")
			} else {
				// Otherwise, make the Album to move the Song to …
				os_signpost(.begin, log: updateLog, name: "Move a Song to a new Album")
				
				let existingCollection = song.container!.container!
				existingCollection.albums(sorted: false).forEach { $0.index += 1 }
				
				let newAlbum = Album(context: managedObjectContext)
				newAlbum.albumPersistentID = newAlbumPersistentID_asInt64
				newAlbum.index = 0
				newAlbum.container = existingCollection
				// We'll set releaseDateEstimate later.
				
				// … and then move the Song to that Album.
				song.index = 0
				song.container = newAlbum
				
				// Make a note of the new Album.
				existingAlbums_byInt64[newAlbumPersistentID_asInt64] = newAlbum
				
				os_signpost(.end, log: updateLog, name: "Move a Song to a new Album")
			}
		}
		
		// We'll delete empty Albums and Collections and reindex Songs and Albums later.
	}
	
}
