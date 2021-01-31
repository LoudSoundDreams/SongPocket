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
	final func deleteManagedObjects(forSongsWith songIDs: [NSManagedObjectID]) {
		os_signpost(.begin, log: Self.importChangesMainLog, name: "3. Delete Managed Objects")
		defer {
			os_signpost(.end, log: Self.importChangesMainLog, name: "3. Delete Managed Objects")
		}
		
		for songID in songIDs {
			let songToDelete = managedObjectContext.object(with: songID)
			managedObjectContext.delete(songToDelete)
		}
		
		deleteEmptyAlbums()
		deleteEmptyCollections()
	}
	
	private func deleteEmptyAlbums() {
		let albumsFetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
		// Order doesn't matter.
		let allAlbums = managedObjectContext.objectsFetched(for: albumsFetchRequest)
		
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
		let collectionsFetchRequest: NSFetchRequest<Collection> = Collection.fetchRequest()
		// Order doesn't matter.
		let allCollections = managedObjectContext.objectsFetched(for: collectionsFetchRequest)
		
		for collection in allCollections {
			guard
				let contents = collection.contents,
				contents.count == 0
			else { continue }
			managedObjectContext.delete(collection)
		}
		
		collectionsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		let allRemainingCollectionsInOrder = managedObjectContext.objectsFetched(for: collectionsFetchRequest)
		
		for index in 0 ..< allRemainingCollectionsInOrder.count {
			let remainingCollection = allRemainingCollectionsInOrder[index]
			remainingCollection.index = Int64(index)
		}
	}
	
}
