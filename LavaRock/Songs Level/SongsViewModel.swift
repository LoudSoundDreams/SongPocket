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
	let lastDeliberatelyOpenedContainer: LibraryContainer?
	let context: NSManagedObjectContext
	var groups: [GroupOfLibraryItems]
}

extension SongsViewModel: LibraryViewModel {
	static let entityName = "Song"
	static let numberOfSectionsAboveLibraryItems = 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 2
	
	func refreshed() -> Self {
		// Check `lastDeliberatelyOpenedContainer` to figure out which `Song`s to show.
		if let album = lastDeliberatelyOpenedContainer as? Album {
			return Self(
				lastDeliberatelyOpenedContainer: lastDeliberatelyOpenedContainer,
				containers: [album],
				context: context)
		} else if let collection = lastDeliberatelyOpenedContainer as? Collection {
			let albums = collection.albums()
			return Self(
				lastDeliberatelyOpenedContainer: lastDeliberatelyOpenedContainer,
				containers: albums,
				context: context)
		} else {
			// `lastDeliberatelyOpenedContainer == nil`. We're showing all `Song`s.
			let allAlbums = Album.allFetched(context: context)
			return Self(
				lastDeliberatelyOpenedContainer: lastDeliberatelyOpenedContainer,
				containers: allAlbums,
				context: context)
		}
	}
}

extension SongsViewModel {
	
	// TO DO: Put the contents of `refreshed()` here?
	init(
		lastDeliberatelyOpenedContainer: LibraryContainer?,
		containers: [NSManagedObject],
		context: NSManagedObjectContext
	) {
		self.lastDeliberatelyOpenedContainer = lastDeliberatelyOpenedContainer
		groups = containers.map {
			GroupOfSongs(
				entityName: Self.entityName,
				container: $0,
				context: context)
		}
		self.context = context
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
