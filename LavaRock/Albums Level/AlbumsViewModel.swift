//
//  AlbumsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct AlbumsViewModel {
	// LibraryViewModel
	let lastSpecificContainer: LibraryContainer?
	let context: NSManagedObjectContext
	var groups: [GroupOfLibraryItems]
}

extension AlbumsViewModel: LibraryViewModel {
	static let entityName = "Album"
	static let numberOfSectionsAboveLibraryItems = FeatureFlag.allRow ? 1 : 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 0
	
	// Identical to counterpart in `SongsViewModel`.
	func refreshed() -> Self {
		let managedObject = lastSpecificContainer as? NSManagedObject
		let wasDeleted = managedObject?.managedObjectContext == nil
		let refreshedLastSpecificContainer = wasDeleted ? nil : lastSpecificContainer
		
		return Self(
			lastSpecificContainer: refreshedLastSpecificContainer,
			context: context)
	}
}

extension AlbumsViewModel {
	
	init(
		lastSpecificContainer: LibraryContainer?,
		context: NSManagedObjectContext
	) {
		self.lastSpecificContainer = lastSpecificContainer
		self.context = context
		
		// Check `lastSpecificContainer` to figure out which `Album`s to show.
		let containers: [NSManagedObject] = {
			if let collection = lastSpecificContainer as? Collection {
				return [collection]
			} else if lastSpecificContainer == nil {
				// We're showing all `Album`s.
				let allCollections = Collection.allFetched(context: context)
				return allCollections
			} else {
				fatalError("`AlbumsViewModel.init` with unknown type for `lastSpecificContainer`.")
			}
		}()
		groups = containers.map {
			GroupOfCollectionsOrAlbums(
				entityName: Self.entityName,
				container: $0,
				context: context)
		}
	}
	
	// Similar to `SongsViewModel.album`.
	func collection(forSection section: Int) -> Collection {
		let group = group(forSection: section)
		return group.container as! Collection
	}
	
	// Similar to counterpart in `AlbumsViewModel`.
	func differenceOfGroupsInferringMoves(
		toMatch newGroups: [GroupOfCollectionsOrAlbums]
	) -> CollectionDifference<GroupOfCollectionsOrAlbums> {
		let oldGroups = groups as! [GroupOfCollectionsOrAlbums]
		let difference = newGroups.difference(from: oldGroups) { oldGroup, newGroup in
			oldGroup.container!.objectID == newGroup.container!.objectID
		}.inferringMoves()
		return difference
	}
	
	// MARK: - “Moving Albums” Mode
	
	func updatedAfterMovingIntoOnlyGroup(
		albumsWith albumIDs: [NSManagedObjectID]
	) -> Self {
		guard let destinationCollection = onlyGroup?.container as? Collection else {
			return self
		}
		
		destinationCollection.moveHere(
			albumsWith: albumIDs,
			context: context)
		
		let newItemsForOnlyGroup = destinationCollection.albums()
		
		var twin = self
		twin.groups[0].setItems(newItemsForOnlyGroup)
		return twin
	}
	
}
