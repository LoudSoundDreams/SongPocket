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
	let lastSpecificallyOpenedContainer: LibraryContainer?
	let context: NSManagedObjectContext
	var groups: [GroupOfLibraryItems]
}

extension AlbumsViewModel: LibraryViewModel {
	static let entityName = "Album"
	static let numberOfSectionsAboveLibraryItems = FeatureFlag.allRow ? 1 : 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 0
	
	func refreshed() -> Self {
		// Check `lastSpecificallyOpenedContainer` to figure out which `Album`s to show.
		if let collection = lastSpecificallyOpenedContainer as? Collection {
			return Self(
				lastSpecificallyOpenedContainer: lastSpecificallyOpenedContainer,
				containers: [collection],
				context: context)
		} else {
			// `lastSpecificallyOpenedContainer == nil`. We're showing all `Album`s.
			let allCollections = Collection.allFetched(context: context)
			return Self(
				lastSpecificallyOpenedContainer: lastSpecificallyOpenedContainer,
				containers: allCollections,
				context: context)
		}
	}
}

extension AlbumsViewModel {
	
	// TO DO: Put the contents of `refreshed()` here?
	init(
		lastSpecificallyOpenedContainer: LibraryContainer?,
		containers: [NSManagedObject],
		context: NSManagedObjectContext
	) {
		self.lastSpecificallyOpenedContainer = lastSpecificallyOpenedContainer
		groups = containers.map {
			GroupOfCollectionsOrAlbums(
				entityName: Self.entityName,
				container: $0,
				context: context)
		}
		self.context = context
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
