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
		// Here, you can update any attributes on each Song. But it's best to not store data on each Song in the first place unless we have to, because we'll have to manually keep it up to date.
		
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
		
		var knownAlbumPersistentIDs = [Int64]()
		var existingAlbums = [Album]()
		for song in potentiallyOutdatedSongs {
			knownAlbumPersistentIDs.append(song.container!.albumPersistentID)
			existingAlbums.append(song.container!)
		}
		
		for song in potentiallyOutdatedSongs.reversed() {
			
			let knownAlbumPersistentID = song.container!.albumPersistentID
			let newAlbumPersistentID = song.mpMediaItem()!.albumPersistentID
			
//			print("")
//			print("Checking album for \(song.titleFormattedOrPlaceholder()).")
//			print("Previously known albumPersistentID: \(UInt64(bitPattern: knownAlbumPersistentID))")
//			print("New albumPersistentID: \(newAlbumPersistentID)")
			
			if knownAlbumPersistentID == Int64(bitPattern: newAlbumPersistentID) {
				continue
				
			} else { // This is a Song we recognize, but its albumPersistentID has changed.
				
				if !knownAlbumPersistentIDs.contains(Int64(bitPattern: newAlbumPersistentID)) { // We've never seen this albumPersistentID before, so make a new Album for it.
					knownAlbumPersistentIDs.append(Int64(bitPattern: newAlbumPersistentID))
					let newAlbum = Album(context: managedObjectContext)
					existingAlbums.append(newAlbum)
					
					newAlbum.container = song.container!.container!
					for album in newAlbum.container!.contents! { // For each Album in the same Collection as the new Album
						(album as! Album).index += 1
					}
					newAlbum.index = 0
					newAlbum.albumPersistentID = Int64(bitPattern: newAlbumPersistentID)
					// We'll set releaseDateEstimate later.
					
					song.index = 0
					song.container = newAlbum
					
				} else { // This Song's albumPersistentID has changed, but we already have an Album for it, so add it to that Album.
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
				
				// We'll delete empty Albums (and Collections) later.
			}
		}
	}
	
}
