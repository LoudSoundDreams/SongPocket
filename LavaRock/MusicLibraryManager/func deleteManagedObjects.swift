//
//  func deleteManagedObjects.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import OSLog

extension MusicLibraryManager {
	
	// Delete Songs for media items that are no longer in the Music library, and then any empty Albums, and then any empty Collections.
	final func deleteManagedObjects(
		for songs: Set<Song>
	) {
		os_signpost(.begin, log: importLog, name: "4. Delete Managed Objects")
		defer {
			os_signpost(.end, log: importLog, name: "4. Delete Managed Objects")
		}
		
		songs.forEach {
			managedObjectContext.delete($0)
			// WARNING: This leaves gaps in the Song indexes within each Album. You must reindex the Songs within each Album later.
		}
		
		deleteEmptyAlbums_withoutReindex()
		Collection.deleteAllEmpty(via: managedObjectContext)
	}
	
	private func deleteEmptyAlbums_withoutReindex() {
		let allAlbums = Album.allFetched(
			via: managedObjectContext,
			ordered: false)
		
		allAlbums.forEach { album in
			if album.isEmpty() {
				managedObjectContext.delete(album)
				// WARNING: This leaves gaps in the Album indexes within each Collection. You must reindex the Albums within each Collection later.
			}
		}
	}
	
}
