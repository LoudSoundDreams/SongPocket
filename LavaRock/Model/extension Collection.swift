//
//  extension Collection.swift
//  LavaRock
//
//  Created by h on 2020-12-17.
//

import CoreData

extension Collection: LibraryItem {
	// Enables [Collection].reindex()
}

extension Collection: LibraryContainer {
	// Enables isEmpty()
}

extension Collection {
	
	// If nil, `proposedTitle` was nil or "".
	static func titleNotEmptyAndNotTooLong(
		from proposedTitle: String?
	) -> String? {
		guard
			let proposedTitle = proposedTitle,
			proposedTitle != ""
		else {
			return nil
		}

		let trimmedTitle = proposedTitle.prefix(255) // In case the user pastes a dangerous amount of text
		if trimmedTitle != proposedTitle {
			return trimmedTitle + "…" // Do we need to localize this?
		} else {
			return String(trimmedTitle)
		}
	}
	
	// MARK: - Core Data
	
	// This is the same as in Album.
	static func allFetched(
		via managedObjectContext: NSManagedObjectContext,
		ordered: Bool = true
	) -> [Collection] {
		let fetchRequest: NSFetchRequest<Collection> = fetchRequest()
		if ordered {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return managedObjectContext.objectsFetched(for: fetchRequest)
	}
	
	// Similar to Album.songs(sorted:).
	final func albums(
		sorted: Bool = true
	) -> [Album] {
		guard let contents = contents else {
			return [Album]()
		}
		
		let unsortedAlbums = contents.map { $0 as! Album }
		if sorted {
			let sortedAlbums = unsortedAlbums.sorted { $0.index < $1.index }
			return sortedAlbums
		} else {
			return unsortedAlbums
		}
	}
	
	static func deleteAllEmpty(
		via managedObjectContext: NSManagedObjectContext
	) {
		var allCollections = Collection.allFetched(via: managedObjectContext)
		
		allCollections.indices.reversed().forEach { index in
			let collection = allCollections[index]
			if collection.isEmpty() {
				managedObjectContext.delete(collection)
				allCollections.remove(at: index)
			}
		}
		
		allCollections.reindex()
	}
	
	// WARNING: Unsafe; leaves Collections in an incoherent state.
	// After calling this, you must delete empty Collections and reindex all Collections.
	static func makeByCombining_withoutDeletingOrReindexing(
		_ selectedCollections: [Collection],
		title titleOfCombinedCollection: String,
		index indexOfCombinedCollection: Int64,
		via managedObjectContext: NSManagedObjectContext
	) -> Collection {
		var selectedAlbums = selectedCollections.flatMap { selectedCollection in
			selectedCollection.albums()
		}
		selectedAlbums.reindex()
		
		let combinedCollection = Collection(context: managedObjectContext)
		combinedCollection.index = indexOfCombinedCollection
		combinedCollection.title = titleOfCombinedCollection
		selectedAlbums.forEach { $0.container = combinedCollection }
		
		return combinedCollection
	}
	
}
