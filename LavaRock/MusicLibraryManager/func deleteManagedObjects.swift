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
			context.delete($0)
			// WARNING: This leaves gaps in the Song indexes within each Album. You must reindex the Songs within each Album later.
		}
		
		Album.deleteAllEmpty_withoutReindex(context: context)
		Collection.deleteAllEmpty(context: context)
	}
	
}
