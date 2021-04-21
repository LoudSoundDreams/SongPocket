//
//  extension Collection.swift
//  LavaRock
//
//  Created by h on 2020-12-17.
//

import CoreData

extension Collection: LibraryItem {
	// Enables [collection].reindex()
}

extension Collection: LibraryContainer {
	// Enables .isEmpty()
}

extension Collection {
	
	static func validatedTitle(from rawProposedTitle: String?) -> String {
		let unwrappedProposedTitle = rawProposedTitle ?? ""
		if unwrappedProposedTitle == "" {
			return LocalizedString.defaultCollectionTitle
		} else {
			let trimmedTitle = unwrappedProposedTitle.prefix(255) // In case the user pastes a dangerous amount of text
			if trimmedTitle != unwrappedProposedTitle {
				return trimmedTitle + "…" // Do we need to localize this?
			} else {
				return String(trimmedTitle)
			}
		}
	}
	
	// MARK: - Core Data
	
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
	
	static func deleteAllEmpty(
		via managedObjectContext: NSManagedObjectContext
	) {
		var allCollections = Collection.allFetched(
			via: managedObjectContext,
			ordered: true)
		
		var indexesOfEmptyCollections = [Int]()
		for index in 0 ..< allCollections.count {
			let collection = allCollections[index]
			if collection.isEmpty() {
				indexesOfEmptyCollections.append(index)
			}
		}
		for index in indexesOfEmptyCollections.reversed() {
			let emptyCollection = allCollections[index]
			managedObjectContext.delete(emptyCollection)
			allCollections.remove(at: index)
		}
		
		allCollections.reindex()
	}
	
}
