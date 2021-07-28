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
	
	final func allowsMoveOrOrganize() -> Bool {
		guard !sectionOfLibraryItems.isEmpty() else {
			return false
		}
		
		return true
	}
	
	final func allowsOrganize() -> Bool {
		guard !sectionOfLibraryItems.isEmpty() else {
			return false
		}
		
		return true
	}
	
	final func allowsMove() -> Bool {
		guard !sectionOfLibraryItems.isEmpty() else {
			return false
		}
		
		return true
	}
	
	// MARK: - Moving or Organizing
	
	final func moveOrOrganizeMenu() -> UIMenu {
		let organizeAction = UIAction(
			title: "Organize Into New Collections…", // TO DO: Localize
			handler: { _ in self.startOrganizingAlbums() })
		let moveAction = UIAction(
			title: "Move To…", // TO DO: Localize
			handler: { _ in self.startMovingAlbums() })
		let children = [
			organizeAction,
			moveAction,
		]
		return UIMenu(children: children.reversed())
	}
	
	// MARK: - Starting Organizing
	
	final func startOrganizingAlbums() {
		
		
	}
	
	// MARK: - Starting Moving
	
	final func startMovingAlbums() {
		
		// Prepare a Collections view to present modally.
		
		guard
			let modalCollectionsNC = storyboard!.instantiateViewController(withIdentifier: "Collections NC") as? UINavigationController,
			let modalCollectionsTVC = modalCollectionsNC.viewControllers.first as? CollectionsTVC
		else { return }
		
		// Initialize an AlbumMoverClipboard for the modal Collections view.
		
		guard let idOfSourceCollection = sectionOfLibraryItems.container?.objectID else { return }
		
		// Note the Albums to move, and to not move.
		var idsOfAlbumsToMove = [NSManagedObjectID]()
		var idsOfAlbumsToNotMove = [NSManagedObjectID]()
		if tableView.indexPathsForSelectedRowsNonNil.isEmpty {
			idsOfAlbumsToMove = sectionOfLibraryItems.items.map { $0.objectID }
		} else {
			indexPaths(forIndexOfSectionOfLibraryItems: 0).forEach { indexPath in
				let album = libraryItem(for: indexPath)
				if tableView.indexPathsForSelectedRowsNonNil.contains(indexPath) {
					// The row is selected.
					idsOfAlbumsToMove.append(album.objectID)
				} else {
					// The row is not selected.
					idsOfAlbumsToNotMove.append(album.objectID)
				}
			}
		}
		modalCollectionsTVC.albumMoverClipboard = AlbumMoverClipboard(
			idOfSourceCollection: idOfSourceCollection,
			idsOfAlbumsBeingMoved: idsOfAlbumsToMove,
			idsOfAlbumsNotBeingMoved: idsOfAlbumsToNotMove,
			delegate: self)
		
		// Make the "move Albums to…" sheet use a child managed object context, so that we can cancel without having to revert our changes.
		let childManagedObjectContext = NSManagedObjectContext(
			concurrencyType: .mainQueueConcurrencyType)
		childManagedObjectContext.parent = managedObjectContext
		modalCollectionsTVC.managedObjectContext = childManagedObjectContext
		
		present(modalCollectionsNC, animated: true)
		
	}
	
}
