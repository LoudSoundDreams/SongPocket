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
				return collection.title ?? ""
		}
	}
	
	func prerowIdentifiersInEachSection() -> [AnyHashable] {
		return prerowsInEachSection
	}
	
	func allowsSortCommand(
		_ sortCommand: SortCommand,
		forItems items: [NSManagedObject]
	) -> Bool {
		switch sortCommand {
			case .folder_name:
				return false
			case .album_recentlyReleased:
				guard let albums = items as? [Album] else {
					return false
				}
				return albums.contains { $0.releaseDateEstimate != nil }
			case .song_track:
				return false
			case
					.random,
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
			context: context,
			parentCollection: freshenedParentCollection,
			prerowsInEachSection: prerowsInEachSection)
	}
}
extension AlbumsViewModel {
	init(
		context: NSManagedObjectContext,
		parentCollection: ParentCollection,
		prerowsInEachSection: [Prerow]
	) {
		self.context = context
		self.parentCollection = parentCollection
		self.prerowsInEachSection = prerowsInEachSection
		
		// Check `viewContainer` to figure out which `Album`s to show.
		let containers: [NSManagedObject] = {
			switch parentCollection {
				case .exists(let collection):
					return [collection]
				case .deleted:
					return []
			}}()
		groups = containers.map { container in
			CollectionsOrAlbumsGroup(
				entityName: Self.entityName,
				container: container,
				context: context)
		}
	}
	
	func albumNonNil(at indexPath: IndexPath) -> Album {
		return itemNonNil(at: indexPath) as! Album
	}
	
	// Similar to `SongsViewModel.album`.
	func collection() -> Collection {
		let group = libraryGroup()
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
	func numberOfRows() -> Int {
		switch parentCollection {
			case .exists:
				let group = libraryGroup()
				return numberOfPrerowsPerSection + group.items.count
			case .deleted:
				return 0 // Without `numberOfPrerowsPerSection`
		}
	}
	
	// MARK: - Organizing
	
	// Returns `true` if the albums to organize have at least 2 different album artists.
	// The “albums to organize” are the selected albums, if any, or all the albums, if this is a specifically opened `Collection`.
	func allows_byAlbumArtist(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		let indexPathsToOrganize = indexPaths_for_all_if_empty_else_unsorted(
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
		let destinationCollection = collection()
		
		destinationCollection.moveAlbumsToBeginning(
			with: albumIDs,
			possiblyToSameCollection: true,
			via: context)
		
		return AlbumsViewModel(
			context: context,
			parentCollection: parentCollection,
			prerowsInEachSection: [])
	}
}
