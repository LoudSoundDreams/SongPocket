//
//  AlbumsViewModel.swift
//  AlbumsViewModel
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct AlbumsViewModel: LibraryViewModel {
	
	let numberOfSectionsAboveLibraryItems = 0 //
	let numberOfRowsAboveLibraryItemsInEachSection = 0
	
	var groups: [GroupOfLibraryItems]
	
	// Similar to SongsViewModel.container.
	func container(forSection section: Int) -> Collection { // "container"? could -> Collection satisfy a protocol requirement -> NSManagedObject as a covariant?
		let group = group(forSection: section)
		return group.container as! Collection
	}
	
	// MARK: - Editing
	
	// MARK: Allowing
	
	func allowsMoveOrOrganize(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		guard !isEmpty() else {
			return false
		}
		
		if selectedIndexPaths.isEmpty {
			return groups.count == 1
		} else {
			return selectedIndexPaths.isWithinSameSection()
		}
	}
	
	func allowsMove(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		return allowsMoveOrOrganize(selectedIndexPaths: selectedIndexPaths)
	}
	
	// MARK: - “Moving Albums” Mode
	
	// MARK: Ending Moving
	
	func itemsAfterMovingHere(
		albumsWith albumIDs: [NSManagedObjectID],
		indexOfGroup: Int, //
		context: NSManagedObjectContext
	) -> [NSManagedObject] {
		guard let destinationCollection = groups[indexOfGroup].container as? Collection else {
			return groups[indexOfGroup].items
		}
		
		destinationCollection.moveHere(
			albumsWith: albumIDs,
			context: context)
		
		let newItems = groups[indexOfGroup].itemsFetched(context: context)
		return newItems
	}
	
}
