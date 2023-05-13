//
//  AlbumsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

enum ParentFolder {
	case exists(Collection)
	case deleted(Collection)
}

struct AlbumsViewModel {
	let parentFolder: ParentFolder
	
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
		switch parentFolder {
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
			case .random, .reverse: return true
			case .folder_name, .song_added, .song_track: return false
			case .album_released:
				guard let albums = items as? [Album] else {
					return false
				}
				return albums.contains { $0.releaseDateEstimate != nil }
		}
	}
	
	// Similar to counterpart in `SongsViewModel`.
	func updatedWithFreshenedData() -> Self {
		let freshenedParent: ParentFolder = {
			switch parentFolder {
				case .exists(let folder):
					if folder.wasDeleted() { // WARNING: You must check this, or the initializer will create groups with no items.
						return .deleted(folder)
					} else {
						return .exists(folder)
					}
				case .deleted(let collection):
					return .deleted(collection)
			}
		}()
		return Self(
			context: context,
			parentFolder: freshenedParent,
			prerowsInEachSection: prerowsInEachSection)
	}
}
extension AlbumsViewModel {
	init(
		context: NSManagedObjectContext,
		parentFolder: ParentFolder,
		prerowsInEachSection: [Prerow]
	) {
		self.context = context
		self.parentFolder = parentFolder
		self.prerowsInEachSection = prerowsInEachSection
		
		// Check `viewContainer` to figure out which `Album`s to show.
		let containers: [NSManagedObject] = {
			switch parentFolder {
				case .exists(let collection):
					return [collection]
				case .deleted:
					return []
			}}()
		groups = containers.map { container in
			FoldersOrAlbumsGroup(
				entityName: Self.entityName,
				container: container,
				context: context)
		}
	}
	
	func albumNonNil(at indexPath: IndexPath) -> Album {
		return itemNonNil(at: indexPath) as! Album
	}
	
	// Similar to `SongsViewModel.album`.
	func folder() -> Collection {
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
		switch parentFolder {
			case .exists:
				let group = libraryGroup()
				return numberOfPrerowsPerSection + group.items.count
			case .deleted:
				return 0 // Without `numberOfPrerowsPerSection`
		}
	}
	
	// MARK: - Organizing
	
	// Returns `true` if the albums to organize have at least 2 different album artists.
	// The “albums to organize” are the selected albums, if any, or all the albums, if this is a specifically opened folder.
	func allowsAutoMove(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		let indexPathsSubjected = indexPaths_for_all_if_empty_else_unsorted(
			selectedIndexPaths: selectedIndexPaths)
		let albumsSubjected = indexPathsSubjected.map { albumNonNil(at: $0) }
		return albumsSubjected.contains {
			let titleOfDestination = $0.albumArtistFormatted()
			return titleOfDestination != $0.container?.title
		}
	}
	
	// MARK: - “Move Albums” Sheet
	
	func updatedAfterMoving(
		albumsWith albumIDs: [NSManagedObjectID],
		toSection section: Int
	) -> Self {
		let destination = folder()
		
		destination.moveAlbumsToBeginning(
			with: albumIDs,
			possiblyToSame: true,
			via: context)
		
		return AlbumsViewModel(
			context: context,
			parentFolder: parentFolder,
			prerowsInEachSection: [])
	}
}
