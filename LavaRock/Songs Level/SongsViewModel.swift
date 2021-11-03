//
//  SongsViewModel.swift
//  SongsViewModel
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct SongsViewModel {
	// LibraryViewModel
	let lastDeliberatelyOpenedContainer: LibraryContainer?
	let context: NSManagedObjectContext
	var groups: [GroupOfLibraryItems]
}

extension SongsViewModel: LibraryViewModel {
	static let entityName = "Song"
	static let numberOfSectionsAboveLibraryItems = 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 2
}

extension SongsViewModel {
	
	init(
		lastDeliberatelyOpenedContainer: LibraryContainer?,
		containers: [NSManagedObject],
		context: NSManagedObjectContext
	) {
		self.lastDeliberatelyOpenedContainer = lastDeliberatelyOpenedContainer
		groups = containers.map {
			GroupOfSongs(
				entityName: Self.entityName,
				container: $0,
				context: context)
		}
		self.context = context
	}
	
	// Similar to AlbumsViewModel.container.
	func container(forSection section: Int) -> Album { // "container"? could -> Album satisfy a protocol requirement -> NSManagedObject as a covariant?
		let group = group(forSection: section)
		return group.container as! Album
	}
	
	func shouldShowDiscNumbers(forSection section: Int) -> Bool {
		let group = group(forSection: section) as? GroupOfSongs
		return group?.shouldShowDiscNumbers ?? false
	}
	
}
