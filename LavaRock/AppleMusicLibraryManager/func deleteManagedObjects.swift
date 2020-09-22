//
//  func deleteManagedObjects.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData

extension AppleMusicLibraryManager {
	
	final func deleteManagedObjects(
		forSongsWith songIDs: [NSManagedObjectID],
		via managedObjectContext: NSManagedObjectContext
	) { // then clean up empty albums, then clean up empty collections
		managedObjectContext.performAndWait {
			for songID in songIDs {
				let songToDelete = managedObjectContext.object(with: songID)
				managedObjectContext.delete(songToDelete)
			}
		}
		
		deleteEmptyAlbums(via: managedObjectContext)
		deleteEmptyCollections(via: managedObjectContext)
	}
	
	private func deleteEmptyAlbums(
		via managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
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
	}
	
	private func deleteEmptyCollections(
		via managedObjectContext: NSManagedObjectContext
	) {
		managedObjectContext.performAndWait {
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
	
}
