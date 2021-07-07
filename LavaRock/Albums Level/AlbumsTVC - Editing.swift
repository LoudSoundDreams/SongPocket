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
	
	// MARK: - Organizing
	
	@objc final func startOrganizingAlbums() {
		
		
	}
	
	// MARK: - Moving or Organizing
	
	// For iOS 14 and later
	final func moveOrOrganizeMenu() -> UIMenu {
		let organizeAction = UIAction(
			title: "Organize Into New Collections…", // TO DO: Localize
//			title: "Move to New Collections By…", // TO DO: Localize
//			title: "Organize Into…", // TO DO: Localize
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
	
	@objc final func showMoveOrOrganizeActionSheet() {
		let actionSheet = UIAlertController(
			title: nil,
			message: nil,
			preferredStyle: .actionSheet)
		
		let organizeAction = UIAlertAction(
			title: "Organize Into…", // TO DO: Localize
			style: .default,
			handler: { _ in self.startOrganizingAlbums() })
		organizeAction.isEnabled = false
		let cancelAlertAction = UIAlertAction.cancel(handler: nil)
		let moveAlertAction = UIAlertAction(
			title: "Move To…", // TO DO: Localize
			style: .default,
			handler: { _ in self.startMovingAlbums() })
		
		actionSheet.addAction(organizeAction)
		actionSheet.addAction(moveAlertAction)
		actionSheet.addAction(cancelAlertAction)
		
		present(actionSheet, animated: true)
	}
	
	// MARK: - Starting Moving Albums
	
	@objc final func startMovingAlbums() {
		
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
			for indexPath in indexPaths(forIndexOfSectionOfLibraryItems: 0) {
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
