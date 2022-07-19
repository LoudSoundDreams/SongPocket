//
//  SongsViewModel.swift
//  SongsViewModel
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct SongsViewModel {
	// `LibraryViewModel`
	let viewContainer: LibraryViewContainer
	let context: NSManagedObjectContext
	let numberOfPresections = Section_I(0)
	var numberOfPrerowsPerSection: Row_I { Row_I(prerowsInEachSection.count) }
	var groups: ColumnOfLibraryItems
	
	enum Prerow {
		case coverArt
		case albumInfo
	}
	let prerowsInEachSection: [Prerow] = [.coverArt, .albumInfo]
}
extension SongsViewModel: LibraryViewModel {
	static let entityName = "Song"
	
	func viewContainerIsSpecific() -> Bool {
		return Enabling.multialbum ? false : true
	}
	
	func bigTitle() -> String {
		switch viewContainer {
		case .library:
			return LRString.songs
		case
				.container(let container),
				.deleted(let container):
			let album = container as! Album
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
	
	func updatedWithFreshenedData() -> Self {
		let freshenedViewContainer = viewContainer.freshened()
		return Self(
			viewContainer: freshenedViewContainer,
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
				let allCollections = Collection.allFetched(ordered: true, via: context)
				let allAlbums = allCollections.flatMap { $0.albums(sorted: true) }
				return allAlbums
			case .container(let container):
				let album = container as! Album
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
	func album(for section: Section_I) -> Album {
		let group = group(for: section)
		return group.container as! Album
	}
	
	enum RowCase {
		case prerow(Prerow)
		case song
	}
	func rowCase(for indexPath: IndexPath) -> RowCase {
		let row = indexPath.row_i
		if row < numberOfPrerowsPerSection {
			let associatedValue = prerowsInEachSection[row.value]
			return .prerow(associatedValue)
		} else {
			return .song
		}
	}
	
	// Time complexity: O(n), where “n” is the number of groups
	func indexPath(for album: Album) -> IndexPath? {
		if let indexOfMatchingGroup = groups.firstIndex(where: { group in
			album.objectID == group.container?.objectID
		}) {
			return IndexPath(
				Row_I(0),
				in: Section_I(numberOfPresections.value + indexOfMatchingGroup))
		} else {
			return nil
		}
	}
}
