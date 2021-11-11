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
	let lastSpecificContainer: LibraryContainer?
	let context: NSManagedObjectContext
	var groups: [GroupOfLibraryItems]
}

extension SongsViewModel: LibraryViewModel {
	static let entityName = "Song"
	static let numberOfSectionsAboveLibraryItems = 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 2
	
	// Identical to counterpart in `AlbumsViewModel`.
	func refreshed() -> Self {
		let managedObject = lastSpecificContainer as? NSManagedObject
		let wasDeleted = managedObject?.managedObjectContext == nil // WARNING: You must check this, or the initializer will create groups with no items.
		let refreshedLastSpecificContainer = wasDeleted ? nil : lastSpecificContainer
		
		return Self(
			lastSpecificContainer: refreshedLastSpecificContainer,
			context: context)
	}
}

extension SongsViewModel {
	
	init(
		lastSpecificContainer: LibraryContainer?,
		context: NSManagedObjectContext
	) {
		self.lastSpecificContainer = lastSpecificContainer
		self.context = context
		
		// Check `lastSpecificContainer` to figure out which `Song`s to show.
		let containers: [NSManagedObject] = {
			if let album = lastSpecificContainer as? Album {
				return [album]
			} else if let collection = lastSpecificContainer as? Collection {
				let albums = collection.albums()
				return albums
			} else if lastSpecificContainer == nil {
				// We're showing all `Song`s.
				let allCollections = Collection.allFetched(context: context)
				let allAlbums = allCollections.flatMap { $0.albums() }
				return allAlbums
			} else {
				fatalError("`SongsViewModel.init` with unknown type for `lastSpecificContainer`.")
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
