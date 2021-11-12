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
	let lastSpecificContainer: OpenedContainer
	let context: NSManagedObjectContext
	var groups: [GroupOfLibraryItems]
}

extension SongsViewModel: LibraryViewModel {
	static let entityName = "Song"
	static let numberOfSectionsAboveLibraryItems = 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 2
	
	var isSpecificallyOpenedContainer: Bool {
		if FeatureFlag.allRow {
			switch lastSpecificContainer {
			case
					.library,
					.collection:
				return false
			case .album:
				return true
			case .deleted:
				return false
			}
		} else {
			return true
		}
	}
	
	// Identical to counterpart in `AlbumsViewModel`.
	func refreshed() -> Self {
		let wasDeleted = lastSpecificContainer.wasDeleted() // WARNING: You must check this, or the initializer will create groups with no items.
		let newLastSpecificContainer: OpenedContainer = wasDeleted ? .deleted : lastSpecificContainer
		
		return Self(
			lastSpecificContainer: newLastSpecificContainer,
			context: context)
	}
}

extension SongsViewModel {
	
	init(
		lastSpecificContainer: OpenedContainer,
		context: NSManagedObjectContext
	) {
		self.lastSpecificContainer = lastSpecificContainer
		self.context = context
		
		// Check `lastSpecificContainer` to figure out which `Song`s to show.
		let containers: [NSManagedObject] = {
			switch lastSpecificContainer {
			case .library:
				let allCollections = Collection.allFetched(context: context)
				let allAlbums = allCollections.flatMap { $0.albums() }
				return allAlbums
			case .collection(let collection):
				let albums = collection.albums()
				return albums
			case .album(let album):
				return [album]
			case .deleted:
				return []
			}
		}()
		groups = containers.map {
			GroupOfSongs(
				entityName: Self.entityName,
				container: $0,
				context: context)
		}
	}
	
	// Similar to `AlbumsViewModel.collection`.
	func album(forSection section: Int) -> Album {
		let group = group(forSection: section)
		return group.container as! Album
	}
	
	// Similar to counterpart in `AlbumsViewModel`.
	func differenceOfGroupsInferringMoves(
		toMatch newGroups: [GroupOfSongs]
	) -> CollectionDifference<GroupOfSongs> {
		let oldGroups = groups as! [GroupOfSongs]
		let difference = newGroups.difference(from: oldGroups) { oldGroup, newGroup in
			oldGroup.container!.objectID == newGroup.container!.objectID
		}.inferringMoves()
		return difference
	}
	
	func shouldShowDiscNumbers(forSection section: Int) -> Bool {
		let group = group(forSection: section) as? GroupOfSongs
		return group?.shouldShowDiscNumbers ?? false
	}
	
}
