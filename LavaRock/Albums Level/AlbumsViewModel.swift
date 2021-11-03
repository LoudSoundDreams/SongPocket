//
//  AlbumsViewModel.swift
//  AlbumsViewModel
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct AlbumsViewModel {
	// LibraryViewModel
	let lastDeliberatelyOpenedContainer: LibraryContainer?
	let context: NSManagedObjectContext
	var groups: [GroupOfLibraryItems]
}

extension AlbumsViewModel: LibraryViewModel {
	static let entityName = "Album"
	static let numberOfSectionsAboveLibraryItems = FeatureFlag.allRow ? 1 : 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 0
}

extension AlbumsViewModel {
	
	init(
		lastDeliberatelyOpenedContainer: LibraryContainer?,
		containers: [NSManagedObject],
		context: NSManagedObjectContext
	) {
		self.lastDeliberatelyOpenedContainer = lastDeliberatelyOpenedContainer
		groups = containers.map {
			GroupOfCollectionsOrAlbums(
				entityName: Self.entityName,
				container: $0,
				context: context)
		}
		self.context = context
	}
	
	// Similar to SongsViewModel.container.
	func container(forSection section: Int) -> Collection { // "container"? could -> Collection satisfy a protocol requirement -> NSManagedObject as a covariant?
		let group = group(forSection: section)
		return group.container as! Collection
	}
	
	// MARK: - “Moving Albums” Mode
	
	func itemsAfterMovingHere(
		albumsWith albumIDs: [NSManagedObjectID],
		indexOfGroup: Int //
	) -> [NSManagedObject] {
		guard let destinationCollection = groups[indexOfGroup].container as? Collection else {
			return groups[indexOfGroup].items
		}
		
		destinationCollection.moveHere(
			albumsWith: albumIDs,
			context: context)
		
		let newItems = destinationCollection.albums()
		return newItems
	}
	
}
