//
//  SongsViewModel.swift
//  SongsViewModel
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

enum ParentAlbum {
	case exists(Album)
	case deleted(Album)
}

struct SongsViewModel {
	let parentAlbum: ParentAlbum
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	let numberOfPresections = 0
	var numberOfPrerowsPerSection: Int {
		prerowsInEachSection.count
	}
	var groups: ColumnOfLibraryItems
	
	enum Prerow {
		case coverArt
		case albumInfo
	}
	let prerowsInEachSection: [Prerow] = [
		.coverArt,
		.albumInfo,
	]
}
extension SongsViewModel: LibraryViewModel {
	static let entityName = "Song"
	
	func bigTitle() -> String {
		switch parentAlbum {
		case
				.exists(let album),
				.deleted(let album):
			return album.representativeTitleFormattedOrPlaceholder()
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
		case
				.title,
				.newestFirst,
				.oldestFirst:
			return false
		case
				.trackNumber:
			return true
		case
				.shuffle,
				.reverse:
			return true
		}
	}
	
	// Similar to counterpart in `AlbumsViewModel`.
	func updatedWithFreshenedData() -> Self {
		let freshenedParentAlbum: ParentAlbum = {
			switch parentAlbum {
			case .exists(let album):
				if album.wasDeleted() { // WARNING: You must check this, or the initializer will create groups with no items.
					return .deleted(album)
				} else {
					return .exists(album)
				}
			case .deleted(let album):
				return .deleted(album)
			}
		}()
		return Self(
			parentAlbum: freshenedParentAlbum,
			context: context)
	}
}
extension SongsViewModel {
	init(
		parentAlbum: ParentAlbum,
		context: NSManagedObjectContext
	) {
		self.parentAlbum = parentAlbum
		self.context = context
		
		// Check `viewContainer` to figure out which `Song`s to show.
		let containers: [NSManagedObject] = {
			switch parentAlbum {
			case .exists(let album):
				return [album]
			case .deleted:
				return []
			}}()
		groups = containers.map {
			SongsGroup(
				entityName: Self.entityName,
				container: $0,
				context: context)
		}
	}
	
	func songNonNil(at indexPath: IndexPath) -> Song {
		return itemNonNil(at: indexPath) as! Song
	}
	
	// Similar to `AlbumsViewModel.collection`.
	func album(forSection section: Int) -> Album {
		let group = group(forSection: section)
		return group.container as! Album
	}
	
	enum RowCase {
		case prerow(Prerow)
		case song
	}
	func rowCase(for indexPath: IndexPath) -> RowCase {
		let row = indexPath.row
		if row < numberOfPrerowsPerSection {
			let associatedValue = prerowsInEachSection[row]
			return .prerow(associatedValue)
		} else {
			return .song
		}
	}
	
	// Similar to counterpart in `AlbumsViewModel`.
	func numberOfRows(forSection section: Int) -> Int {
		switch parentAlbum {
		case .exists:
			let group = group(forSection: section)
			return numberOfPrerowsPerSection + group.items.count
		case .deleted:
			return 0 // Without `numberOfPrerowsPerSection`
		}
	}
}
