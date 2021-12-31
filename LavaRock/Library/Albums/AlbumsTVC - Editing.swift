//
//  AlbumsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit
import CoreData
import OSLog

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
			let libraryNC = storyboard?.instantiateViewController(
				withIdentifier: LibraryNC.identifier) as? UINavigationController,
			let collectionsTVC = libraryNC.viewControllers.first as? CollectionsTVC,
			let albumsViewModel = viewModel as? AlbumsViewModel
		else { return }
		
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil
		
		let indexPathsToOrganize = albumsViewModel.sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: selectedIndexPaths)
		let albumsToOrganize = indexPathsToOrganize.map { albumsViewModel.albumNonNil(at: $0) }
		
		// Create a child managed object context to begin the changes in.
		let childContext = NSManagedObjectContext(.mainQueue)
		childContext.parent = viewModel.context
		
		// Move the `Album`s it makes sense to move, and save the object IDs of the rest, to keep them selected.
		let clipboard = Self.organizeByAlbumArtistAndReturnClipboard(
			albumsToOrganize,
			via: childContext,
			delegateForClipboard: self)
		let selectedAlbums = selectedIndexPaths.map { albumsViewModel.albumNonNil(at: $0) }
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
		present(libraryNC, animated: true) {
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
	
	private static func organizeByAlbumArtistAndReturnClipboard(
		_ albumsToOrganize: [Album],
		via context: NSManagedObjectContext,
		delegateForClipboard: OrganizeAlbumsDelegate
	) -> OrganizeAlbumsClipboard {
		let log = OSLog.albumsView
		os_signpost(.begin, log: log, name: "Preview organizing Albums")
		defer {
			os_signpost(.end, log: log, name: "Preview organizing Albums")
		}
		
		// If an `Album` is already in a `Collection` with a title that matches its album artist, then leave it there.
		// Otherwise, move the `Album` to the first `Collection` with a matching title.
		// If there is no matching `Collection`, then create one.
		// Put new `Collection`s at the top, in the order that the album artists first appear among the `Album`s we're moving.
		
		// Results
		var movedAlbums: Set<Album> = []
		var idsOfUnmovedAlbums: Set<NSManagedObjectID> = []
		
		// Work notes
		var newCollectionsByTitle: [String: Collection] = [:]
		let existingCollections = Collection.allFetched(via: context)
		let existingCollectionsByTitle = Dictionary(grouping: existingCollections) { $0.title! }
		
		albumsToOrganize.forEach { album in
			// Similar to `newAlbumAndMaybeNewCollectionMade`.
			
			let titleOfDestinationCollection = album.albumArtistFormattedOrPlaceholder()
			
			guard album.container!.title != titleOfDestinationCollection else {
				idsOfUnmovedAlbums.insert(album.objectID)
				return
			}
			
			movedAlbums.insert(album)
			
			// If we've created a matching `Collection` …
			if let matchingNewCollection = newCollectionsByTitle[titleOfDestinationCollection] {
				// … then move the `Album` to the end of that `Collection`.
				os_signpost(.begin, log: log, name: "Move Album to matching new Collection")
				matchingNewCollection.moveAlbumsToEnd_withoutDeleteOrReindexSourceCollections(
					with: [album.objectID],
					possiblyToSameCollection: false,
					via: context)
				os_signpost(.end, log: log, name: "Move Album to matching new Collection")
			} else if // Otherwise, if we previously had a matching `Collection` …
				let matchingExistingCollection = existingCollectionsByTitle[titleOfDestinationCollection]?.first
			{
				// … then move the `Album` to the beginning of that `Collection`.
				os_signpost(.begin, log: log, name: "Move Album to matching existing Collection")
				matchingExistingCollection.moveAlbumsToBeginning_withoutDeleteOrReindexSourceCollections(
					with: [album.objectID],
					possiblyToSameCollection: false,
					via: context)
				os_signpost(.end, log: log, name: "Move Album to matching existing Collection")
			} else {
				// Otherwise, create a matching `Collection`…
				let newCollection = Collection(
					index: Int64(newCollectionsByTitle.count),
					before: existingCollections,
					title: titleOfDestinationCollection,
					context: context)
				newCollectionsByTitle[titleOfDestinationCollection] = newCollection
				
				// … and then move the `Album` to that `Collection`.
				os_signpost(.begin, log: log, name: "Move Album to new Collection")
				newCollection.moveAlbumsToEnd_withoutDeleteOrReindexSourceCollections(
					with: [album.objectID],
					possiblyToSameCollection: false,
					via: context)
				os_signpost(.end, log: log, name: "Move Album to new Collection")
			}
		}
		
		// Create the `OrganizeAlbumsClipboard` to return.
		let idsOfSourceCollections = Set(albumsToOrganize.map { $0.container!.objectID })
		let idsOfMovedAlbums = Set(movedAlbums.map { $0.objectID })
		let idsOfDestinationCollections = Set(idsOfMovedAlbums.map {
			(context.object(with: $0) as! Album).container!.objectID
		})
		return OrganizeAlbumsClipboard(
			idsOfSourceCollections: idsOfSourceCollections,
			idsOfUnmovedAlbums: idsOfUnmovedAlbums,
			idsOfMovedAlbums: idsOfMovedAlbums,
			idsOfDestinationCollections: idsOfDestinationCollections,
			delegate: delegateForClipboard)
	}
	
	private func startMoving() {
		// Prepare a Collections view to present modally.
		guard
			let libraryNC = storyboard?.instantiateViewController(
				withIdentifier: LibraryNC.identifier) as? UINavigationController,
			let collectionsTVC = libraryNC.viewControllers.first as? CollectionsTVC,
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
		childContext.parent = viewModel.context
		collectionsTVC.viewModel = CollectionsViewModel(
			context: childContext,
			prerowsInEachSection: [.createCollection])
		
		present(libraryNC, animated: true)
	}
}
