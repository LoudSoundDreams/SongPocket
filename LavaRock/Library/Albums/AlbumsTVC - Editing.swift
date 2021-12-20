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
		
		// Create a child managed object context to begin the changes in.
		let childContext = NSManagedObjectContext.withParent(viewModel.context)
		
		// Move the `Album`s it makes sense to move, and save the object IDs of the rest, to keep them selected.
		let clipboard = AlbumsViewModel.organizeByAlbumArtistAndReturnClipboard(
			albumsToOrganize,
			via: childContext,
			delegateForClipboard: self)
		let selectedItems = tableView.indexPathsForSelectedRowsNonNil.compactMap {
			viewModel.itemOptional(at: $0)
		}
		idsOfAlbumsToKeepSelected = Set(selectedItems.compactMap {
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
				if #available(iOS 15, *) {
					self.tableView.reconfigureRows(at: self.tableView.indexPathsForVisibleRowsNonNil)
				} else {
					self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRowsNonNil, with: .none)
				}
			}
			collectionsTVC.reflectPlayer()
		}
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
		collectionsTVC.moveAlbumsClipboard = MoveAlbumsClipboard(
			albumsBeingMoved: albumsToMove,
			delegate: self)
		
		// Make the "move albums" sheet use a child managed object context, so that we can cancel without having to revert our changes.
		let childContext = NSManagedObjectContext.withParent(viewModel.context)
		collectionsTVC.viewModel = CollectionsViewModel(
			context: childContext,
			prerowsInEachSection: [.createCollection])
		
		present(collectionsNC, animated: true)
	}
	
}
