//
//  AlbumsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	final func moveOrOrganizeMenu() -> UIMenu {
		let organizeAction = UIAction(
			title: LocalizedString.organizeIntoNewSections,
			handler: { _ in self.startOrganizing() })
		let moveAction = UIAction(
			title: LocalizedString.moveTo,
			handler: { _ in self.startMoving() })
		return UIMenu(children: [
			organizeAction,
			moveAction,
		].reversed())
	}
	
	private func startOrganizing() {
		
		
	}
	
	final func startMoving() {
		guard let albumsViewModel = viewModel as? AlbumsViewModel else { return }
		
		// Prepare a Collections view to present modally.
		guard
			let modalCollectionsNC = storyboard!.instantiateViewController(withIdentifier: "Collections NC") as? UINavigationController,
			let modalCollectionsTVC = modalCollectionsNC.viewControllers.first as? CollectionsTVC
		else { return }
		
		// Initialize an AlbumMoverClipboard for the modal Collections view.
		let indexPathsToMove = albumsViewModel.sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		let idsOfAlbumsToMove = indexPathsToMove.map {
			albumsViewModel.itemNonNil(at: $0).objectID
		}
		let idsOfSourceCollections = Set(indexPathsToMove.map {
			albumsViewModel.collection(forSection: $0.section).objectID
		})
		modalCollectionsTVC.albumMoverClipboard = AlbumMoverClipboard(
			idsOfAlbumsBeingMoved: idsOfAlbumsToMove,
			idsOfSourceCollections: idsOfSourceCollections,
			delegate: self)
		
		// Make the "move Albums to…" sheet use a child managed object context, so that we can cancel without having to revert our changes.
		let childContext = NSManagedObjectContext.withParent(albumsViewModel.context)
		modalCollectionsTVC.viewModel = CollectionsViewModel(context: childContext)
		
		present(modalCollectionsNC, animated: true)
	}
	
}
