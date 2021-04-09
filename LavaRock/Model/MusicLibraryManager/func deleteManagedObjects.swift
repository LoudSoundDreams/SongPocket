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
		}
		
		deleteEmptyAlbums()
		deleteEmptyCollections()
	}
	
	private func deleteEmptyAlbums() {
		let allAlbums = Album.allFetched(
			via: managedObjectContext,
			ordered: false)
		
		for album in allAlbums {
			guard
				let contents = album.contents,
				contents.count == 0
			else { continue }
			managedObjectContext.delete(album)
			// Note: This leaves gaps in the Album indexes within each Collection. We'll reindex the Albums later.
		}
	}
	
	private func deleteEmptyCollections() {
		let allCollections = Collection.allFetched(
			via: managedObjectContext,
			ordered: false)
		
		for collection in allCollections {
			guard
				let contents = collection.contents,
				contents.count == 0
			else { continue }
			managedObjectContext.delete(collection)
		}
		
		var allRemainingCollectionsInOrder = Collection.allFetched(
			via: managedObjectContext,
			ordered: true)
		
		allRemainingCollectionsInOrder.reindex()
	}
	
}
