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
	
	let context: NSManagedObjectContext
	let numberOfSectionsAboveLibraryItems = 0 //
	let numberOfRowsAboveLibraryItemsInEachSection = 0
	
	weak var reflector: LibraryViewModelReflecting?
	
	var groups: [GroupOfLibraryItems]
	
	func navigationItemTitleOptional() -> String? {
		guard groups.count == 1 else {
			return nil
		}
		return (groups[0].container as? Collection)?.title
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
	
	// MARK: - Editing
	
	// MARK: Moving or Organizing
	
	func allowsMoveOrOrganize(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		guard !isEmpty() else {
			return false
		}
		
		if selectedIndexPaths.isEmpty {
			return groups.count == 1
		} else {
			return selectedIndexPaths.isWithinSameSection()
		}
	}
	
	// MARK: Starting Moving
	
	func allowsMove(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		return allowsMoveOrOrganize(selectedIndexPaths: selectedIndexPaths)
	}
	
	// MARK: - “Moving Albums” Mode
	
	// MARK: Ending Moving
	
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
