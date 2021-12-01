//
//  AlbumsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	final func makeOrganizeOrMoveMenu() -> UIMenu {
		let organizeElement: UIMenuElement = {
			let organizeAction = UIAction(
				title: LocalizedString.organizeByAlbumArtistEllipsis,
				handler: { _ in self.startOrganizing() })
			
			guard #available(iOS 15, *) else {
				return organizeAction
			}
			// UIKit runs `UIDeferredMenuElement.uncached`’s closure every time it uses the menu element.
			return UIDeferredMenuElement.uncached({ useMenuElements in
				let allowed = (self.viewModel as? AlbumsViewModel)?.allowsOrganize(
					selectedIndexPaths: self.tableView.indexPathsForSelectedRowsNonNil) ?? false
				organizeAction.attributes = allowed ? [] : .disabled
				useMenuElements([organizeAction])
			})
		}()
		
		let moveElement = UIAction(
			title: LocalizedString.moveToEllipsis,
			handler: { _ in self.startMoving() })
		
		return UIMenu(
			children: [
				organizeElement,
				moveElement,
			].reversed()
		)
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
		
		// Preview the data changes in a child managed object context, and make the "organize albums" sheet show them.
		collectionsTVC.viewModel = albumsViewModel.makeCollectionsViewModel_inNewChildContext(
			organizingIntoNewCollections: albumsToOrganize)
		
		// Provide the extra data that the "organize albums" sheet needs.
		let idsOfOrganizedAlbums = albumsToOrganize.map { $0.objectID }
		let idsOfSourceCollections = Set(albumsToOrganize.map { $0.container!.objectID })
		collectionsTVC.albumOrganizerClipboard = AlbumOrganizerClipboard(
			idsOfOrganizedAlbums: idsOfOrganizedAlbums,
			idsOfSourceCollections: idsOfSourceCollections,
			context: collectionsTVC.viewModel.context,
			delegate: self)
		
		present(collectionsNC, animated: true)
	}
	
	private func startMoving() {
		// Prepare a Collections view to present modally.
		guard
			let collectionsNC = storyboard?.instantiateViewController(
				withIdentifier: "Collections NC") as? UINavigationController,
			let collectionsTVC = collectionsNC.viewControllers.first as? CollectionsTVC
		else { return }
		
		// Provide the extra data that the "move albums" sheet needs.
		let indexPathsToMove = viewModel.sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		let albumsToMove = indexPathsToMove.map {
			viewModel.itemNonNil(at: $0) as! Album
		}
		collectionsTVC.albumMoverClipboard = AlbumMoverClipboard(
			albumsBeingMoved: albumsToMove,
			delegate: self)
		
		// Make the "move albums" sheet use a child managed object context, so that we can cancel without having to revert our changes.
		let childContext = NSManagedObjectContext.withParent(viewModel.context)
		collectionsTVC.viewModel = CollectionsViewModel(
			context: childContext,
			numberOfPrerowsPerSection: 1)
//			numberOfPrerowsPerSection: 0) // RB2DO: Delete this
		
		present(collectionsNC, animated: true)
	}
	
}
