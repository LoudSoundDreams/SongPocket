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
		if selectedIndexPaths.isEmpty {
			guard viewContainerIsSpecific() else {
				return false
			}
			let items = groups.flatMap({ $0.items })
			guard let albums = items as? [Album] else {
				return false
			}
			return albums.contains { !$0.isInCollectionMatchingAlbumArtist() }
		} else {
			let items = selectedIndexPaths.map { itemNonNil(at: $0) }
			guard let albums = items as? [Album] else {
				return false
			}
			return albums.contains { !$0.isInCollectionMatchingAlbumArtist() }
		}
	}
	
	func makeCollectionsViewModel_inNewChildContext(
		organizingIntoNewCollections albumsToOrganize: [Album]
	) -> CollectionsViewModel {
		let childContext = NSManagedObjectContext.withParent(context)
		
		// Move each `Album` to the first `Collection` with a title that matches the album artist.
		// If an `Album` is already in a `Collection` with a matching title, then leave it there.
		// If no `Collection` has a matching title, then create one.
		// Go from the bottom `Album` to the top.
		var allCollections = Collection.allFetched(via: childContext)
		var allCollectionsGroupedByTitle = Dictionary(grouping: allCollections) { $0.title! }
		albumsToOrganize.reversed().forEach { album in
			// Similar to `newAlbumAndMaybeNewCollectionMade`.
			
			let titleOfDestinationCollection
			= album.albumArtist() ?? Album.placeholderAlbumArtist
			
			guard album.container!.title != titleOfDestinationCollection else { return }
			
			// If we already have a matching `Collection` to put the `Album` into …
			if let matchingCollection = allCollectionsGroupedByTitle[titleOfDestinationCollection]?.first {
				// … then move the `Album` to that `Collection`.
				matchingCollection.moveAlbumsToBeginning_withoutDelete(
					with: [album.objectID], // It might be faster to `Album`s by their album artist first, then move whole groups at once.
					via: childContext)
			} else {
				// Otherwise, create the `Collection` to move the `Album` to …
				let newCollection = Collection(
					beforeAllOtherCollections: allCollections,
					title: titleOfDestinationCollection,
					context: childContext)
				allCollections.append(newCollection)
				allCollectionsGroupedByTitle[titleOfDestinationCollection] = [newCollection]
				
				// … and then move the `Album` to that `Collection`.
				newCollection.moveAlbumsToBeginning_withoutDelete(
					with: [album.objectID],
					via: childContext)
			}
		}
		
		return CollectionsViewModel(
			context: childContext,
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
