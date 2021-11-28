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
	let viewContainer: LibraryViewContainer
	let context: NSManagedObjectContext
	let numberOfSectionsAboveLibraryItems = 0
	let numberOfRowsAboveLibraryItemsInEachSection = 2
	var groups: [GroupOfLibraryItems]
}

extension SongsViewModel: LibraryViewModel {
	static let entityName = "Song"
	
	func viewContainerIsSpecific() -> Bool {
		return FeatureFlag.multialbum ? false : true
	}
	
	func bigTitle() -> String {
		switch viewContainer {
		case .library:
			return LocalizedString.songs
		case
				.container(let container),
				.deleted(let container):
			let album = container as! Album
			return album.titleFormattedOrPlaceholder()
		}
	}
	
	func refreshed() -> Self {
		let refreshedViewContainer = viewContainer.refreshed()
		return Self(
			viewContainer: refreshedViewContainer,
			context: context)
	}
}

extension SongsViewModel {
	
	init(
		viewContainer: LibraryViewContainer,
		context: NSManagedObjectContext
	) {
		self.viewContainer = viewContainer
		self.context = context
		
		// Check `viewContainer` to figure out which `Song`s to show.
		let containers: [NSManagedObject] = {
			switch viewContainer {
			case .library:
				let allCollections = Collection.allFetched(context: context)
				let allAlbums = allCollections.flatMap { $0.albums() }
				return allAlbums
			case .container(let container):
				let album = container as! Album
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
	
	// Time complexity: O(n), where "n" is the number of groups
	func indexPath(for album: Album) -> IndexPath? {
		if let indexOfMatchingGroup = groups.firstIndex(where: { group in
			group.container?.objectID == album.objectID
		}) {
			return IndexPath(
				row: 0,
				section: numberOfSectionsAboveLibraryItems + indexOfMatchingGroup)
		} else {
			return nil
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
