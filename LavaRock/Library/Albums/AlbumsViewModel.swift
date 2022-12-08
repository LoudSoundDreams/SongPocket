//
//  AlbumsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

enum ParentCollection {
	case exists(Collection)
	case deleted(Collection)
}

struct AlbumsViewModel {
	let parentCollection: ParentCollection
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	let numberOfPresections = 0
	var numberOfPrerowsPerSection: Int {
		prerowsInEachSection.count
	}
	var groups: ColumnOfLibraryItems
	
	enum Prerow {
		case moveHere
	}
	var prerowsInEachSection: [Prerow]
}
extension AlbumsViewModel: LibraryViewModel {
	static let entityName = "Album"
	
	func bigTitle() -> String {
		switch parentCollection {
		case
				.exists(let collection),
				.deleted(let collection):
			return collection.title ?? LRString.albums
		}
	}
	
	func prerowIdentifiersInEachSection() -> [AnyHashable] {
		return prerowsInEachSection
	}
	
	func allowsSortOption(
		_ sortOption: LibrarySortOption,
		forItems items: [NSManagedObject]
	) -> Bool {
		switch sortOption {
		case .title:
			return false
		case
				.newestFirst,
				.oldestFirst:
			guard let albums = items as? [Album] else {
				return false
			}
			return albums.contains { $0.releaseDateEstimate != nil }
		case .trackNumber:
			return false
		case
				.shuffle,
				.reverse:
			return true
		}
	}
	
	// Similar to counterpart in `SongsViewModel`.
	func updatedWithFreshenedData() -> Self {
		let freshenedParentCollection: ParentCollection = {
			switch parentCollection {
			case .exists(let collection):
				if collection.wasDeleted() { // WARNING: You must check this, or the initializer will create groups with no items.
					return .deleted(collection)
				} else {
					return .exists(collection)
				}
			case .deleted(let collection):
				return .deleted(collection)
			}
		}()
		return Self(
			parentCollection: freshenedParentCollection,
			context: context,
			prerowsInEachSection: prerowsInEachSection)
	}
}
extension AlbumsViewModel {
	init(
		parentCollection: ParentCollection,
		context: NSManagedObjectContext,
		prerowsInEachSection: [Prerow]
	) {
		self.parentCollection = parentCollection
		self.context = context
		self.prerowsInEachSection = prerowsInEachSection
		
		// Check `viewContainer` to figure out which `Album`s to show.
		let containers: [NSManagedObject] = {
			switch parentCollection {
			case .exists(let collection):
				return [collection]
			case .deleted:
				return []
			}}()
		groups = containers.map {
			CollectionsOrAlbumsGroup(
				entityName: Self.entityName,
				container: $0,
				context: context)
		}
	}
	
	func albumNonNil(at indexPath: IndexPath) -> Album {
		return itemNonNil(at: indexPath) as! Album
	}
	
	// Similar to `SongsViewModel.album`.
	func collection(forSection section: Int) -> Collection {
		let group = group(forSection: section)
		return group.container as! Collection
	}
	
	enum RowCase {
		case prerow(Prerow)
		case album
	}
	func rowCase(for indexPath: IndexPath) -> RowCase {
		let row = indexPath.row
		if row < numberOfPrerowsPerSection {
			return .prerow(prerowsInEachSection[indexPath.row])
		} else {
			return .album
		}
	}
	
	// Similar to counterpart in `SongsViewModel`.
	func numberOfRows(forSection section: Int) -> Int {
		switch parentCollection {
		case .exists:
			let group = group(forSection: section)
			return numberOfPrerowsPerSection + group.items.count
		case .deleted:
			return 0 // Without `numberOfPrerowsPerSection`
		}
	}
	
	// MARK: - Organizing
	
	// Returns `true` if the albums to organize have at least 2 different album artists.
	// The “albums to organize” are the selected albums, if any, or all the albums, if this is a specifically opened `Collection`.
	func allowsOrganize(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		let indexPathsToOrganize = unsortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: selectedIndexPaths)
		let albumsToOrganize = indexPathsToOrganize.map { albumNonNil(at: $0) }
		return albumsToOrganize.contains {
			$0.representativeAlbumArtistFormattedOrPlaceholder() != $0.container?.title
		}
	}
	
	// MARK: - “Move Albums” Sheet
	
	func updatedAfterMoving(
		albumsWith albumIDs: [NSManagedObjectID],
		toSection section: Int
	) -> Self {
		let destinationCollection = collection(forSection: section)
		
		destinationCollection.moveAlbumsToBeginning(
			with: albumIDs,
			possiblyToSameCollection: true,
			via: context)
		
		return AlbumsViewModel(
			parentCollection: parentCollection,
			context: context,
			prerowsInEachSection: [])
	}
}
