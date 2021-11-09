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
	let lastSpecificallyOpenedContainer: LibraryContainer?
	let context: NSManagedObjectContext
	var groups: [GroupOfLibraryItems]
}

extension SongsViewModel: LibraryViewModel {
	static let entityName = "Song"
	static let numberOfSectionsAboveLibraryItems = 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 2
	
	// Identical to counterpart in `AlbumsViewModel`.
	func refreshed() -> Self {
		return Self(
			lastSpecificallyOpenedContainer: lastSpecificallyOpenedContainer,
			context: context)
	}
}

extension SongsViewModel {
	
	// TO DO: Put the contents of `refreshed()` here?
	init(
		lastSpecificallyOpenedContainer: LibraryContainer?,
		context: NSManagedObjectContext
	) {
		self.lastSpecificallyOpenedContainer = lastSpecificallyOpenedContainer
		self.context = context
		
		// Check `lastSpecificallyOpenedContainer` to figure out which `Song`s to show.
		let containers: [NSManagedObject] = {
			if let album = lastSpecificallyOpenedContainer as? Album {
				return [album]
			} else if let collection = lastSpecificallyOpenedContainer as? Collection {
				let albums = collection.albums()
				return albums
			} else if lastSpecificallyOpenedContainer == nil {
				// We're showing all `Song`s.
				let allAlbums = Album.allFetched(context: context)
				return allAlbums
			} else {
				fatalError("`SongsViewModel.refreshed()` with unknown type for `lastSpecificallyOpenedContainer`.")
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
