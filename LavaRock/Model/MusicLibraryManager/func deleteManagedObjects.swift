//
//  func deleteManagedObjects.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import OSLog

extension MusicLibraryManager {
	
	private static let deleteManagedObjectsLog = OSLog(
		subsystem: subsystemForOSLog,
		category: "3. Delete Managed Objects")
	
	// Delete Songs for media items that are no longer in the Music library, and then any empty Albums, and then any empty Collections.
	final func deleteManagedObjects(
		for songs: Set<Song>
	) {
		os_signpost(.begin, log: Self.importChangesMainLog, name: "3. Delete Managed Objects")
		defer {
			os_signpost(.end, log: Self.importChangesMainLog, name: "3. Delete Managed Objects")
		}
		
		for songToDelete in songs {
			managedObjectContext.delete(songToDelete)
			// WARNING: This leaves gaps in the Song indexes within each Album. You must reindex the Songs within each Album later.
		}
		
		deleteEmptyAlbums_WithoutReindex()
		Collection.deleteAllEmpty(via: managedObjectContext)
	}
	
	private func deleteEmptyAlbums_WithoutReindex() {
		let allAlbums = Album.allFetched(
			via: managedObjectContext,
			ordered: false)
		
		for album in allAlbums {
			if album.contents == nil || album.contents?.count == 0 {
				managedObjectContext.delete(album)
				// WARNING: This leaves gaps in the Album indexes within each Collection. You must reindex the Albums within each Collection later.
			}
		}
	}
	
}
