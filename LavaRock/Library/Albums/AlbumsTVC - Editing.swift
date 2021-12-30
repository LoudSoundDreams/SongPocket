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
		// Prepare a Collections view to present modally.
		guard
			let collectionsNC = storyboard?.instantiateViewController(
				withIdentifier: "Collections NC") as? UINavigationController,
			let collectionsTVC = collectionsNC.viewControllers.first as? CollectionsTVC,
			let albumsViewModel = viewModel as? AlbumsViewModel
		else { return }
		
		let indexPathsToOrganize = albumsViewModel.sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		let albumsToOrganize = indexPathsToOrganize.map { albumsViewModel.albumNonNil(at: $0) }
		
		// Create a child managed object context to begin the changes in.
		let childContext = NSManagedObjectContext(.mainQueue)
		childContext.parent = albumsViewModel.context
		
		// Move the `Album`s it makes sense to move, and save the object IDs of the rest, to keep them selected.
		let clipboard = AlbumsViewModel.organizeByAlbumArtistAndReturnClipboard(
			albumsToOrganize,
			via: childContext,
			delegateForClipboard: self)
		let selectedAlbums = tableView.indexPathsForSelectedRowsNonNil.map {
			albumsViewModel.albumNonNil(at: $0)
		}
		idsOfAlbumsToKeepSelected = Set(selectedAlbums.compactMap {
			let selectedAlbumID = $0.objectID
			if clipboard.idsOfUnmovedAlbums.contains(selectedAlbumID) {
				return selectedAlbumID
			} else {
				return nil
			}
		})
		
		collectionsTVC.willOrganizeAlbumsStickyNote = WillOrganizeAlbumsStickyNote(
			prompt: clipboard.prompt,
			idsOfSourceCollections: clipboard.idsOfSourceCollections)
		
		// Make the "organize albums" sheet show the child context, but only after we present it.
		guard let oldCollectionsViewModel = collectionsTVC.viewModel as? CollectionsViewModel else { return }
		present(collectionsNC, animated: true) {
			collectionsTVC.organizeAlbumsClipboard = clipboard
			
			let collectionsViewModelPreviewingOrganizeAlbums = CollectionsViewModel(
				context: childContext,
				prerowsInEachSection: [])
			let indexPathsOfDestinationCollectionsThatAlreadyExisted = oldCollectionsViewModel.indexPathsForAllItems().filter {
				let collection = oldCollectionsViewModel.collectionNonNil(at: $0)
				return clipboard.idsOfDestinationCollections.contains(collection.objectID)
			}
			// Similar to `reflectDatabase`.
			collectionsTVC.setViewModelAndMoveRows(
				firstReloading: indexPathsOfDestinationCollectionsThatAlreadyExisted,
				collectionsViewModelPreviewingOrganizeAlbums
			) {
				self.tableView.reconfigureRows(at: self.tableView.indexPathsForVisibleRowsNonNil)
			}
			collectionsTVC.reflectPlayer()
		}
	}
	
	private func startMoving() {
		// Prepare a Collections view to present modally.
		guard
			let collectionsNC = storyboard?.instantiateViewController(
				withIdentifier: "Collections NC") as? UINavigationController,
			let collectionsTVC = collectionsNC.viewControllers.first as? CollectionsTVC,
			let albumsViewModel = viewModel as? AlbumsViewModel
		else { return }
		
		// Provide the extra data that the "move albums" sheet needs.
		let indexPathsToMove = albumsViewModel.sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		let albumsToMove = indexPathsToMove.map { albumsViewModel.albumNonNil(at: $0) }
		collectionsTVC.moveAlbumsClipboard = MoveAlbumsClipboard(
			albumsBeingMoved: albumsToMove,
			delegate: self)
		
		// Make the "move albums" sheet use a child managed object context, so that we can cancel without having to revert our changes.
		let childContext = NSManagedObjectContext(.mainQueue)
		childContext.parent = albumsViewModel.context
		collectionsTVC.viewModel = CollectionsViewModel(
			context: childContext,
			prerowsInEachSection: [.createCollection])
		
		present(collectionsNC, animated: true)
	}
	
}
