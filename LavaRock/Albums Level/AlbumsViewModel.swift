//
//  AlbumsViewModel.swift
//  AlbumsViewModel
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct AlbumsViewModel: LibraryViewModel {
	
	// MARK: - LibraryViewModel
	
	static let entityName = "Album"
	static let numberOfSectionsAboveLibraryItems = 0 //
	static let numberOfRowsAboveLibraryItemsInEachSection = 0
	
	let context: NSManagedObjectContext
	
	weak var reflector: LibraryViewModelReflecting?
	
	var groups: [GroupOfLibraryItems]
	
	func navigationItemTitleOptional() -> String? {
		guard let onlyGroup = onlyGroup else {
			return nil
		}
		return (onlyGroup.container as? Collection)?.title
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
			GroupOfCollectionsOrAlbums(
				entityName: Self.entityName,
				container: $0,
				context: context)
		}
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
