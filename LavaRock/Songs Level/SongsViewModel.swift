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
	static let numberOfSectionsAboveLibraryItems = 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 2
	
	let context: NSManagedObjectContext
	
	weak var reflector: LibraryViewModelReflecting?
	
	var groups: [GroupOfLibraryItems]
	
	func navigationItemTitleOptional() -> String? {
		guard let onlyGroup = onlyGroup else {
			return nil
		}
		return (onlyGroup.container as? Album)?.titleFormattedOrPlaceholder()
	}
	
	// MARK: - Miscellaneous
	
	init(
		containers: [NSManagedObject],
		context: NSManagedObjectContext,
		reflector: LibraryViewModelReflecting
	) {
		self.context = context
		self.reflector = reflector
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
