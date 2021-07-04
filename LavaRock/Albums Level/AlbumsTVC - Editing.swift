//
//  AlbumsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// MARK: - Allowing
	
	final func allowsStartMovingAlbums() -> Bool {
		guard !sectionOfLibraryItems.items.isEmpty else {
			return false
		}
		
		return true
	}
	
	// MARK: - Starting Moving Albums
	
	@objc final func startMovingAlbums() {
		
		// Prepare a Collections view to present modally.
		
		guard
			let modalCollectionsNC = storyboard!.instantiateViewController(withIdentifier: "Collections NC") as? UINavigationController,
			let modalCollectionsTVC = modalCollectionsNC.viewControllers.first as? CollectionsTVC
		else {
			return
		}
		
		// Initialize an AlbumMoverClipboard for the modal Collections view.
		
		guard let idOfSourceCollection = sectionOfLibraryItems.container?.objectID else { return }
		
		// Note the Albums to move, and to not move.
		var idsOfAlbumsToMove = [NSManagedObjectID]()
		var idsOfAlbumsToNotMove = [NSManagedObjectID]()
		if tableView.indexPathsForSelectedRowsNonNil.isEmpty {
			idsOfAlbumsToMove = sectionOfLibraryItems.items.map { $0.objectID }
		} else {
			for indexPath in indexPaths(forIndexOfSectionOfLibraryItems: 0) {
				let album = libraryItem(for: indexPath)
				if tableView.indexPathsForSelectedRowsNonNil.contains(indexPath) { // If the row is selected.
					idsOfAlbumsToMove.append(album.objectID)
				} else { // The row is not selected.
					idsOfAlbumsToNotMove.append(album.objectID)
				}
			}
		}
		modalCollectionsTVC.albumMoverClipboard = AlbumMoverClipboard(
			idOfSourceCollection: idOfSourceCollection,
			idsOfAlbumsBeingMoved: idsOfAlbumsToMove,
			idsOfAlbumsNotBeingMoved: idsOfAlbumsToNotMove,
			delegate: self
		)
		
		// Make the destination operate in a child managed object context, so that you can cancel without saving your changes.
		let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		childManagedObjectContext.parent = managedObjectContext
		modalCollectionsTVC.managedObjectContext = childManagedObjectContext
		
		present(modalCollectionsNC, animated: true)
		
	}
	
}
