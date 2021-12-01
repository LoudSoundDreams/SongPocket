//
//  AlbumsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct AlbumsViewModel {
	// LibraryViewModel
	let viewContainer: LibraryViewContainer
	let context: NSManagedObjectContext
	let numberOfPresections = 0
	private(set) var numberOfPrerowsPerSection: Int
	var groups: [GroupOfLibraryItems]
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
		case .reverse:
			return true
		}
	}
	
	func updatedWithRefreshedData() -> Self {
		let refreshedViewContainer = viewContainer.refreshed()
		return Self(
			viewContainer: refreshedViewContainer,
			context: context,
			numberOfPrerowsPerSection: numberOfPrerowsPerSection)
	}
}

extension AlbumsViewModel {
	
	init(
		viewContainer: LibraryViewContainer,
		context: NSManagedObjectContext,
		numberOfPrerowsPerSection: Int
	) {
		self.viewContainer = viewContainer
		self.context = context
		self.numberOfPrerowsPerSection = numberOfPrerowsPerSection
		
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
	
	// MARK: - Organizing
	
	// Returns `true` if the albums to organize have at least 2 different album artists.
	// The "albums to organize" are the selected albums, if any, or all the albums, if this is a specifically opened `Collection`.
	func allowsOrganize(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		let indexPathsToOrganize = unsortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: selectedIndexPaths)
		guard let albumsToOrganize = indexPathsToOrganize.map({
			itemNonNil(at: $0)
		}) as? [Album]
		else {
			return false
		}
		return albumsToOrganize.contains { !$0.isInCollectionMatchingAlbumArtist() }
	}
	
	func makeCollectionsViewModel_inNewChildContext(
		organizingIntoNewCollections albumsToOrganize: [Album]
	) -> CollectionsViewModel {
		let context = NSManagedObjectContext.withParent(context) // Shadowing so that we don't accidentally refer to `self.context`.
		
		// If an `Album` is already in a `Collection` with a title that matches its album artist, then leave it there.
		// Otherwise, move the `Album` to the first `Collection` with a matching title.
		// If there is no matching `Collection`, then create one.
		// New `Collection`s should go at the top, in the order of the first `Album` we're moving with each album artist.
		var newCollectionsByTitle: [String: Collection] = [:]
		let existingCollections = Collection.allFetched(via: context)
		let existingCollectionsByTitle = Dictionary(grouping: existingCollections) { $0.title! }
		albumsToOrganize.forEach { album in
			// Similar to `newAlbumAndMaybeNewCollectionMade`.
			
			let titleOfDestinationCollection
			= album.albumArtist() ?? Album.unknownAlbumArtistPlaceholder
			
			guard album.container!.title != titleOfDestinationCollection else { return }
			
			// If we've created a matching `Collection` …
			if let matchingNewCollection = newCollectionsByTitle[titleOfDestinationCollection] {
				// … then move the `Album` to the end of that `Collection`.
				matchingNewCollection.moveAlbumsToEnd_withoutDelete(
					with: [album.objectID],
					via: context)
			} else if // Otherwise, if we previously had a matching `Collection` …
				let matchingExistingCollection = existingCollectionsByTitle[titleOfDestinationCollection]?.first
			{
				// … then move the `Album` to the beginning of that `Collection`.
				matchingExistingCollection.moveAlbumsToBeginning_withoutDelete(
					with: [album.objectID],
					via: context)
			} else {
				// Otherwise, create a matching `Collection`…
				let newCollection = Collection(
					index: Int64(newCollectionsByTitle.count),
					before: existingCollections,
					title: titleOfDestinationCollection,
					context: context)
				newCollectionsByTitle[titleOfDestinationCollection] = newCollection
				
				// … and then move the `Album` to that `Collection`.
				newCollection.moveAlbumsToEnd_withoutDelete(
					with: [album.objectID],
					via: context)
			}
		}
		
		return CollectionsViewModel(
			context: context,
			numberOfPrerowsPerSection: 0)
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
			via: context)
		
		let newItemsForOnlyGroup = destinationCollection.albums()
		
		var twin = self
		twin.numberOfPrerowsPerSection = 0
		twin.groups[0].setItems(newItemsForOnlyGroup)
		return twin
	}
	
}
