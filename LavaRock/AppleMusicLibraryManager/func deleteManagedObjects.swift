//
//  func deleteManagedObjects.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData

extension AppleMusicLibraryManager {
	
	// Delete Songs for media items that are no longer in the Apple Music library, and then any empty Albums, and then any empty Collections.
	final func deleteManagedObjects(forSongsWith songIDs: [NSManagedObjectID]) {
		for songID in songIDs {
			let songToDelete = managedObjectContext.object(with: songID)
			managedObjectContext.delete(songToDelete)
		}
		
		deleteEmptyAlbums()
		deleteEmptyCollections()
	}
	
	private func deleteEmptyAlbums() {
		let albumsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
		// Order doesn't matter.
		let allAlbums = managedObjectContext.objectsFetched(for: albumsFetchRequest) as! [Album]
		
		for album in allAlbums {
			guard
				let contents = album.contents,
				contents.count == 0
			else { continue }
			managedObjectContext.delete(album)
			// TO DO: This leaves gaps in the album indexes within each collection.
		}
	}
	
	private func deleteEmptyCollections() {
		let collectionsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Collection")
		// Order doesn't matter.
		let allCollections = managedObjectContext.objectsFetched(for: collectionsFetchRequest) as! [Collection]
		
		for collection in allCollections {
			guard
				let contents = collection.contents,
				contents.count == 0
			else { continue }
			managedObjectContext.delete(collection)
			// TO DO: This leaves gaps in the collection indexes.
		}
	}
	
}
