//
//  func updateManagedObjects.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import MediaPlayer

extension AppleMusicLibraryManager {
	
	final func updateManagedObjects(
		forSongsWith songIDs: [NSManagedObjectID],
		toMatch mediaItems: [MPMediaItem]
	) {
		// Here, you can update any stored attributes on each song. But unless we have to, it's best to not store that data in the first place, because we'll have to manually keep up to date.
		
		updateRelationshipsBetweenAlbumsAndSongs(
			with: songIDs,
			toMatch: mediaItems)
	}
	
	private func updateRelationshipsBetweenAlbumsAndSongs(
		with songIDs: [NSManagedObjectID],
		toMatch mediaItems: [MPMediaItem]
	) {
		var potentiallyOutdatedSongs = [Song]()
		for songID in songIDs {
			let song = managedObjectContext.object(with: songID) as! Song
			potentiallyOutdatedSongs.append(song)
		}
		
		potentiallyOutdatedSongs.sort() { $0.index < $1.index }
		potentiallyOutdatedSongs.sort() { $0.container!.index < $1.container!.index }
		potentiallyOutdatedSongs.sort() { $0.container!.container!.index < $1.container!.container!.index }
		/*
		print("")
		for song in potentiallyOutdatedSongs {
		print(song.titleFormattedOrPlaceholder())
		print("Container \(song.container!.container!.index), album \(song.container!.index), song \(song.index)")
		}
		*/
		
		var knownAlbumPersistentIDs = [Int64]()
		var existingAlbums = [Album]()
		for song in potentiallyOutdatedSongs {
			knownAlbumPersistentIDs.append(song.container!.albumPersistentID)
			existingAlbums.append(song.container!)
		}
		
		for song in potentiallyOutdatedSongs.reversed() {
			
			let knownAlbumPersistentID = song.container!.albumPersistentID
			let newAlbumPersistentID = song.mpMediaItem()!.albumPersistentID
			/*
			print("")
			print("Checking album status of \(song.titleFormattedOrPlaceholder()).")
			print("Previously known albumPersistentID: \(UInt64(bitPattern: knownAlbumPersistentID))")
			print("New albumPersistentID: \(newAlbumPersistentID)")
			*/
			
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
					
					song.index = 0
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
					song.index = 0
					song.container = existingAlbum
				}
				
				// We'll delete empty albums (and collections) later.
			}
		}
	}
	
}
