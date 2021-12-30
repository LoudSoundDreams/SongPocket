//
//  AlbumsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData
import OSLog

struct AlbumsViewModel {
	// LibraryViewModel
	let viewContainer: LibraryViewContainer
	let context: NSManagedObjectContext
	let numberOfPresections = 0
	var numberOfPrerowsPerSection: Int { prerowsInEachSection.count }
	var groups: [GroupOfLibraryItems]
	
	enum Prerow {
		case moveHere
	}
	var prerowsInEachSection: [Prerow]
}

extension AlbumsViewModel: LibraryViewModel {
	static let entityName = "Album"
	
	func viewContainerIsSpecific() -> Bool {
		return FeatureFlag.multicollection ? false : true
	}
	
	func bigTitle() -> String {
		switch viewContainer {
		case .library:
			return LocalizedString.albums
		case
				.container(let container),
				.deleted(let container):
			let collection = container as! Collection
			return collection.title ?? LocalizedString.albums
		}
	}
	
	func prerowIdentifiersInEachSection() -> [AnyHashable] {
		return prerowsInEachSection
	}
	
	func allowsSortOption(
		_ sortOption: LibraryTVC.SortOption,
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
				.random,
				.reverse:
			return true
		}
	}
	
	func updatedWithRefreshedData() -> Self {
		let refreshedViewContainer = viewContainer.refreshed()
		return Self(
			viewContainer: refreshedViewContainer,
			context: context,
			prerowsInEachSection: prerowsInEachSection)
	}
}

extension AlbumsViewModel {
	init(
		viewContainer: LibraryViewContainer,
		context: NSManagedObjectContext,
		prerowsInEachSection: [Prerow]
	) {
		self.viewContainer = viewContainer
		self.context = context
		self.prerowsInEachSection = prerowsInEachSection
		
		// Check `viewContainer` to figure out which `Album`s to show.
		let containers: [NSManagedObject] = {
			switch viewContainer {
			case .library:
				let allCollections = Collection.allFetched(via: context)
				return allCollections
			case .container(let container):
				let collection = container as! Collection
				return [collection]
			case .deleted:
				return []
			}
		}()
		groups = containers.map {
			GroupOfCollectionsOrAlbums(
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
			let associatedValue = prerowsInEachSection[row]
			return .prerow(associatedValue)
		} else {
			return .album
		}
	}
	
	// MARK: - Organizing
	
	// Returns `true` if the albums to organize have at least 2 different album artists.
	// The "albums to organize" are the selected albums, if any, or all the albums, if this is a specifically opened `Collection`.
	func allowsOrganize(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		let indexPathsToOrganize = unsortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: selectedIndexPaths)
		let albumsToOrganize = indexPathsToOrganize.map { albumNonNil(at: $0) }
		return albumsToOrganize.contains {
			$0.albumArtistFormattedOrPlaceholder() != $0.container?.title
		}
	}
	
	static func organizeByAlbumArtistAndReturnClipboard(
		_ albumsToOrganize: [Album],
		via context: NSManagedObjectContext,
		delegateForClipboard: OrganizeAlbumsDelegate
	) -> OrganizeAlbumsClipboard {
		let log = OSLog.albumsView
		os_signpost(.begin, log: log, name: "Preview organizing Albums")
		defer {
			os_signpost(.end, log: log, name: "Preview organizing Albums")
		}
		
		// If an `Album` is already in a `Collection` with a title that matches its album artist, then leave it there.
		// Otherwise, move the `Album` to the first `Collection` with a matching title.
		// If there is no matching `Collection`, then create one.
		// Put new `Collection`s at the top, in the order that the album artists first appear among the `Album`s we're moving.
		
		// Results
		var movedAlbums: Set<Album> = []
		var idsOfUnmovedAlbums: Set<NSManagedObjectID> = []
		
		// Work notes
		var newCollectionsByTitle: [String: Collection] = [:]
		let existingCollections = Collection.allFetched(via: context)
		let existingCollectionsByTitle = Dictionary(grouping: existingCollections) { $0.title! }
		
		albumsToOrganize.forEach { album in
			// Similar to `newAlbumAndMaybeNewCollectionMade`.
			
			let titleOfDestinationCollection = album.albumArtistFormattedOrPlaceholder()
			
			guard album.container!.title != titleOfDestinationCollection else {
				idsOfUnmovedAlbums.insert(album.objectID)
				return
			}
			
			movedAlbums.insert(album)
			
			// If we've created a matching `Collection` …
			if let matchingNewCollection = newCollectionsByTitle[titleOfDestinationCollection] {
				// … then move the `Album` to the end of that `Collection`.
				os_signpost(.begin, log: log, name: "Move Album to matching new Collection")
				matchingNewCollection.moveAlbumsToEnd_withoutDeleteOrReindexSourceCollections(
					with: [album.objectID],
					possiblyToSameCollection: false,
					via: context)
				os_signpost(.end, log: log, name: "Move Album to matching new Collection")
			} else if // Otherwise, if we previously had a matching `Collection` …
				let matchingExistingCollection = existingCollectionsByTitle[titleOfDestinationCollection]?.first
			{
				// … then move the `Album` to the beginning of that `Collection`.
				os_signpost(.begin, log: log, name: "Move Album to matching existing Collection")
				matchingExistingCollection.moveAlbumsToBeginning_withoutDeleteOrReindexSourceCollections(
					with: [album.objectID],
					possiblyToSameCollection: false,
					via: context)
				os_signpost(.end, log: log, name: "Move Album to matching existing Collection")
			} else {
				// Otherwise, create a matching `Collection`…
				let newCollection = Collection(
					index: Int64(newCollectionsByTitle.count),
					before: existingCollections,
					title: titleOfDestinationCollection,
					context: context)
				newCollectionsByTitle[titleOfDestinationCollection] = newCollection
				
				// … and then move the `Album` to that `Collection`.
				os_signpost(.begin, log: log, name: "Move Album to new Collection")
				newCollection.moveAlbumsToEnd_withoutDeleteOrReindexSourceCollections(
					with: [album.objectID],
					possiblyToSameCollection: false,
					via: context)
				os_signpost(.end, log: log, name: "Move Album to new Collection")
			}
		}
		
		// Create the `OrganizeAlbumsClipboard` to return.
		let idsOfSourceCollections = Set(albumsToOrganize.map { $0.container!.objectID })
		let idsOfMovedAlbums = Set(movedAlbums.map { $0.objectID })
		let idsOfDestinationCollections = Set(idsOfMovedAlbums.map {
			(context.object(with: $0) as! Album).container!.objectID
		})
		return OrganizeAlbumsClipboard(
			idsOfSourceCollections: idsOfSourceCollections,
			idsOfUnmovedAlbums: idsOfUnmovedAlbums,
			idsOfMovedAlbums: idsOfMovedAlbums,
			idsOfDestinationCollections: idsOfDestinationCollections,
			delegate: delegateForClipboard)
	}
	
	// MARK: - “Move Albums” Sheet
	
	func updatedAfterMovingIntoOnlyGroup(
		albumsWith albumIDs: [NSManagedObjectID]
	) -> Self {
		guard let destinationCollection = onlyGroup?.container as? Collection else {
			return self
		}
		
		destinationCollection.moveAlbumsToBeginning(
			with: albumIDs,
			possiblyToSameCollection: true,
			via: context)
		
		let newItemsForOnlyGroup = destinationCollection.albums(sorted: true)
		
		var twin = self
		twin.prerowsInEachSection = []
		twin.groups[0].setItems(newItemsForOnlyGroup)
		return twin
	}
}
