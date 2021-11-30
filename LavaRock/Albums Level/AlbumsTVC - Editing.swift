//
//  AlbumsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	final func makeMoveOrOrganizeMenu() -> UIMenu {
		let organizeElement: UIMenuElement = {
			if #available(iOS 15, *) {
				// UIKit runs `UIDeferredMenuElement.uncached`’s closure every time it uses the menu element.
				return UIDeferredMenuElement.uncached({ useMenuElements in
					let dynamicOrganizeAction = self.makeDynamicOrganizeAction()
					useMenuElements([dynamicOrganizeAction])
				})
			} else {
				let organizeAction = makeDynamicOrganizeAction()
				organizeAction.title = LocalizedString.organizeEllipsis
				return organizeAction
			}
		}()
		let moveElement: UIMenuElement = {
			if #available(iOS 15, *) {
				return UIDeferredMenuElement.uncached({ useMenuElements in
					let dynamicMoveAction = self.makeDynamicMoveAction()
					useMenuElements([dynamicMoveAction])
				})
			} else {
				let moveAction = makeDynamicMoveAction()
				moveAction.title = LocalizedString.moveToEllipsis
				return moveAction
			}
		}()
		return UIMenu(children: [
			organizeElement,
			moveElement,
		].reversed())
	}
	
	private func makeDynamicOrganizeAction() -> UIAction {
		let formatString = LocalizedString.formatOrganizeXAlbums
		let numberToOrganize = viewModel.countOrAllItemsCountIfNoneSelectedAndViewContainerIsSpecific(
			selectedItemsCount: tableView.indexPathsForSelectedRowsNonNil.count)
		let title = String.localizedStringWithFormat(
			formatString,
			numberToOrganize)
		return UIAction(
			title: title,
			image: UIImage(systemName: "plus.rectangle.on.folder"),
			handler: { _ in self.startOrganizing() })
	}
	
	private func makeDynamicMoveAction() -> UIAction {
		let formatString = LocalizedString.formatMoveXAlbums
		let numberToMove = viewModel.countOrAllItemsCountIfNoneSelectedAndViewContainerIsSpecific(
			selectedItemsCount: tableView.indexPathsForSelectedRowsNonNil.count)
		let title = String.localizedStringWithFormat(
			formatString,
			numberToMove)
		return UIAction(
			title: title,
			image: UIImage(systemName: "folder"),
			handler: { _ in self.startMoving() })
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
		collectionsTVC.albumOrganizerClipboard = AlbumOrganizerClipboard(
			idsOfOrganizedAlbums: idsOfOrganizedAlbums,
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
