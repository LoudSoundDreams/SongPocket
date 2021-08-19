//
//  SongsViewModel.swift
//  SongsViewModel
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct SongsViewModel: LibraryViewModel {
	
	// MARK: - LibraryViewModel
	
	static let entityName = "Song"
	
	let context: NSManagedObjectContext
	let numberOfSectionsAboveLibraryItems = 0
	let numberOfRowsAboveLibraryItemsInEachSection = 2
	
	var groups: [GroupOfLibraryItems]
	
	// MARK: - Miscellaneous
	
	init(
		containers: [NSManagedObject],
		context: NSManagedObjectContext
	) {
		self.context = context
		groups = containers.map {
			GroupOfSongs(
				entityName: Self.entityName,
				container: $0,
				context: context)
		}
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
