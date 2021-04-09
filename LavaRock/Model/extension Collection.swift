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

extension Collection {
	
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
	
}
