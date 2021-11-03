//
//  AlbumsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// Similar to counterpart in `CollectionsTVC`.
	final override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		if FeatureFlag.allRow {
			reloadAllRow(with: .fade)
		}
	}
	
	final func moveOrOrganizeMenu() -> UIMenu {
		let organizeAction = UIAction(
			title: "Organize Into New Collections…", // TO DO: Localize
			handler: { _ in self.startOrganizingAlbums() })
		let moveAction = UIAction(
			title: "Move To…", // TO DO: Localize
			handler: { _ in self.startMovingAlbums() })
		return UIMenu(children: [
			organizeAction,
			moveAction,
		].reversed())
	}
	
	final func startOrganizingAlbums() {
		
		
	}
	
	final func startMovingAlbums() {
		
		guard let albumsViewModel = viewModel as? AlbumsViewModel else { return }
		
		// Prepare a Collections view to present modally.
		guard
			let modalCollectionsNC = storyboard!.instantiateViewController(withIdentifier: "Collections NC") as? UINavigationController,
			let modalCollectionsTVC = modalCollectionsNC.viewControllers.first as? CollectionsTVC
		else { return }
		
		// Get the rows to move.
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil
		let indexPathsToMove = albumsViewModel.selectedOrAllIndexPathsInOnlyGroup(
			selectedIndexPaths: selectedIndexPaths)
		guard let section = indexPathsToMove.first?.section else { return }
		
		// Initialize an AlbumMoverClipboard for the modal Collections view.
		let sourceCollection = albumsViewModel.container(forSection: section)
		let idOfSourceCollection = sourceCollection.objectID
		let idsOfAlbumsToMove = indexPathsToMove.map {
			albumsViewModel.item(at: $0).objectID
		}
		modalCollectionsTVC.albumMoverClipboard = AlbumMoverClipboard(
			idOfSourceCollection: idOfSourceCollection,
			idsOfAlbumsBeingMoved: idsOfAlbumsToMove,
			delegate: self)
		
		// Make the "move Albums to…" sheet use a child managed object context, so that we can cancel without having to revert our changes.
		let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		childContext.parent = albumsViewModel.context
		modalCollectionsTVC.viewModel = CollectionsViewModel(context: childContext)
		
		present(modalCollectionsNC, animated: true)
		
	}
	
}
