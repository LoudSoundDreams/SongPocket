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
				let allCollections = Collection.allFetched(context: context)
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
	
	// Similar to counterpart in `AlbumsViewModel`.
	func differenceOfGroupsInferringMoves(
		toMatch newGroups: [GroupOfCollectionsOrAlbums]
	) -> CollectionDifference<GroupOfCollectionsOrAlbums> {
		let oldGroups = groups as! [GroupOfCollectionsOrAlbums]
		let difference = newGroups.difference(from: oldGroups) { oldGroup, newGroup in
			oldGroup.container!.objectID == newGroup.container!.objectID
		}.inferringMoves()
		return difference
	}
	
	// MARK: - Organizing
	
	func makeCollectionsViewModel_inNewChildContext(
		organizingIntoNewCollections albumsToOrganize: [Album]
	) -> CollectionsViewModel {
		let childContext = NSManagedObjectContext.withParent(context)
		
		// Organize the `Album`s into new `Collection`s.
		var allCollections = Collection.allFetched(
			ordered: false,
			context: childContext)
		var newCollectionsByTitle: [String: Collection] = [:]
		albumsToOrganize.reversed().forEach { album in
			// Similar to `newAlbumAndMaybeNewCollectionMade`.
			
			let titleOfDestinationCollection
			= album.mpMediaItemCollection()?.representativeItem?.albumArtist
			?? Album.placeholderAlbumArtist
			
			// If we've already created a new `Collection` to put the `Album` into …
			if let matchingCollection = newCollectionsByTitle[titleOfDestinationCollection] {
				// … then put the `Album` into that `Collection`.
				matchingCollection.moveAlbumsToBeginning(
					with: [album.objectID],
					context: childContext)
			} else {
				// Otherwise, create the new `Collection` to put the `Album` into …
				let newCollection = Collection(
					beforeAllOtherCollections: allCollections,
					title: titleOfDestinationCollection,
					context: childContext)
				allCollections.append(newCollection)
				newCollectionsByTitle[titleOfDestinationCollection] = newCollection
				
				// … and then put the `Album` into that `Collection`.
				newCollection.moveAlbumsToBeginning(
					with: [album.objectID],
					context: childContext)
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
			context: context)
		
		let newItemsForOnlyGroup = destinationCollection.albums()
		
		var twin = self
		
		
		twin.numberOfPrerowsPerSection = 0
		
		
		twin.groups[0].setItems(newItemsForOnlyGroup)
		return twin
	}
	
}
