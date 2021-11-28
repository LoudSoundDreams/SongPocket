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
			title: LocalizedString.organizeEllipsis,
//			image: UIImage(systemName: "tray.2"),
//			image: UIImage(systemName: "plus.rectangle.on.folder"),
			handler: { _ in self.startOrganizing() })
		let moveAction = UIAction(
			title: LocalizedString.moveToEllipsis,
//			image: UIImage(systemName: "tray"),
//			image: UIImage(systemName: "folder"),
			handler: { _ in self.startMoving() })
		return UIMenu(children: [
			organizeAction,
			moveAction,
		].reversed())
	}
	
	private func startOrganizing() {
		guard let albumsViewModel = viewModel as? AlbumsViewModel else { return }
		
		// Prepare a Collections view to present modally.
		guard
			let collectionsNC = storyboard?.instantiateViewController(
				withIdentifier: "Collections NC") as? UINavigationController,
			let collectionsTVC = collectionsNC.viewControllers.first as? CollectionsTVC
		else { return }
		
		let indexPathsToOrganize = viewModel.sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		let albumsToOrganize = indexPathsToOrganize.map {
			viewModel.itemNonNil(at: $0) as! Album
		}
		
		// Preview the data changes in a child managed object context, and make "organize albums?" sheet show them.
		collectionsTVC.viewModel = albumsViewModel.makeCollectionsViewModel_inNewChildContext(
			organizingIntoNewCollections: albumsToOrganize)
		
		// Provide the extra data that the "organize albums?" sheet needs.
		let idsOfOrganizedAlbums = albumsToOrganize.map { $0.objectID }
		collectionsTVC.albumOrganizerClipboard = AlbumOrganizerClipboard(
			idsOfOrganizedAlbums: idsOfOrganizedAlbums,
			context: collectionsTVC.viewModel.context,
			delegate: self)
		
		present(collectionsNC, animated: true)
	}
	
//	private
	final
	func startMoving() {
		// Prepare a Collections view to present modally.
		guard
			let collectionsNC = storyboard?.instantiateViewController(
				withIdentifier: "Collections NC") as? UINavigationController,
			let collectionsTVC = collectionsNC.viewControllers.first as? CollectionsTVC
		else { return }
		
		// Provide the extra data that the "move albums to…" sheet needs.
		let indexPathsToMove = viewModel.sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		let albumsToMove = indexPathsToMove.map {
			viewModel.itemNonNil(at: $0) as! Album
		}
		collectionsTVC.albumMoverClipboard = AlbumMoverClipboard(
			albumsBeingMoved: albumsToMove,
			delegate: self)
		
		// Make the "move albums to…" sheet use a child managed object context, so that we can cancel without having to revert our changes.
		let childContext = NSManagedObjectContext.withParent(viewModel.context)
		collectionsTVC.viewModel = CollectionsViewModel(context: childContext)
		
		present(collectionsNC, animated: true)
	}
	
}
