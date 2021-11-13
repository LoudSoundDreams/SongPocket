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
	let viewContainer: LibraryViewContainer
	let context: NSManagedObjectContext
	var groups: [GroupOfLibraryItems]
}

extension AlbumsViewModel: LibraryViewModel {
	static let entityName = "Album"
	static let numberOfSectionsAboveLibraryItems = FeatureFlag.allRow ? 1 : 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 0
	
	var viewContainerIsSpecific: Bool {
		if FeatureFlag.allRow {
			switch viewContainer {
			case .library:
				return false
			case .collection:
				return true
			case
					.album,
					.deleted:
				return false
			}
		} else {
			return true
		}
	}
	
	// Identical to counterpart in `SongsViewModel`.
	func refreshed() -> Self {
		let wasDeleted = viewContainer.wasDeleted()
		let newViewContainer: LibraryViewContainer = wasDeleted ? .deleted : viewContainer
		
		return Self(
			viewContainer: newViewContainer,
			context: context)
	}
}

extension AlbumsViewModel {
	
	init(
		viewContainer: LibraryViewContainer,
		context: NSManagedObjectContext
	) {
		self.viewContainer = viewContainer
		self.context = context
		
		// Check `viewContainer` to figure out which `Album`s to show.
		let containers: [NSManagedObject] = {
			switch viewContainer {
			case .library:
				let allCollections = Collection.allFetched(context: context)
				return allCollections
			case .collection(let collection):
				return [collection]
			case .album:
				fatalError("`AlbumsViewModel.init` with an `Album` for `viewContainer`.")
			case .deleted:
				return []
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
