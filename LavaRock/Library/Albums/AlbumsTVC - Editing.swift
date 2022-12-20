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
	func startOrganizing() {
		// Prepare a Collections view to present modally.
		let libraryNC = LibraryNC()
		guard
			let collectionsTVC = libraryNC.viewControllers.first as? CollectionsTVC,
			let albumsViewModel = viewModel as? AlbumsViewModel
		else { return }
		
		let selectedIndexPaths = tableView.selectedIndexPaths
		
		let indexPathsToOrganize = albumsViewModel.sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: selectedIndexPaths)
		let albumsInOriginalContextToMaybeMove = indexPathsToOrganize.map { albumsViewModel.albumNonNil(at: $0) }
		
		// Create a child managed object context to begin the changes in.
		let childContext = NSManagedObjectContext(.mainQueue)
		childContext.parent = viewModel.context
		
		// Move the `Album`s it makes sense to move, and save the object IDs of the rest, to keep them selected.
		let clipboard = Self.organizeByAlbumArtistAndReturnClipboard(
			albumsInOriginalContextToMaybeMove: albumsInOriginalContextToMaybeMove,
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
		
		// Make the “organize albums” sheet show the child context, but only after we present it.
		guard let oldCollectionsViewModel = collectionsTVC.viewModel as? CollectionsViewModel else { return }
		Task {
			await present__async(libraryNC, animated: true)
			
			collectionsTVC.organizeAlbumsClipboard = clipboard
			collectionsTVC.willOrganizeAlbumsStickyNote = nil
			
			let previewOfChanges = CollectionsViewModel(
				context: childContext,
				prerowsInEachSection: [])
			// We might have moved `Album`s into any existing `Collection` other than the source. If so, fade in a highlight on those rows.
			let originalIndexPathsOfCollectionsContainingMovedAlbums = oldCollectionsViewModel.indexPathsForAllItems().filter {
				let collectionID = oldCollectionsViewModel.collectionNonNil(at: $0).objectID
				return clipboard.idsOfCollectionsContainingMovedAlbums.contains(collectionID)
			}
			
			// Similar to `reflectDatabase`.
			let _ = await collectionsTVC.setViewModelAndMoveAndDeselectRowsAndShouldContinue(
				firstReloading: originalIndexPathsOfCollectionsContainingMovedAlbums,
				previewOfChanges,
				runningBeforeContinuation: {
					// Remove the “now playing” marker from the source `Collection`, if necessary.
					collectionsTVC.reflectPlayhead_library()
				})
		}
	}
	
	private static func organizeByAlbumArtistAndReturnClipboard(
		albumsInOriginalContextToMaybeMove: [Album],
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
		// Put new `Collection`s above the source `Collection`, in the order that the album artists first appear among the `Album`s we’re moving.
		
		// Results
		var movedAlbumsInOriginalContext: Set<Album> = []
		var idsOfUnmovedAlbums: Set<NSManagedObjectID> = []
		
		// Work notes
		let indexOfSourceCollection = albumsInOriginalContextToMaybeMove.first!.container!.index
		let collectionsToDisplace: [Collection] = {
			let predicate = NSPredicate(
				format: "index >= %lld",
				indexOfSourceCollection)
			return Collection.allFetched(
				ordered: true,
				predicate: predicate,
				via: context)
		}()
		var newCollectionsByTitle: [String: Collection] = [:]
		let existingCollectionsByTitle: [String: [Collection]] = {
			let existingCollections = Collection.allFetched(ordered: true, via: context)
			return Dictionary(grouping: existingCollections) { $0.title! }
		}()
		
		albumsInOriginalContextToMaybeMove.forEach { album in
			// Similar to `newAlbumAndMaybeNewCollectionMade`.
			
			let titleOfDestinationCollection = album.representativeAlbumArtistFormattedOrPlaceholder()
			
			guard album.container!.title != titleOfDestinationCollection else {
				idsOfUnmovedAlbums.insert(album.objectID)
				return
			}
			
			movedAlbumsInOriginalContext.insert(album)
			
			// If we’ve created a matching new `Collection` …
			if let matchingNewCollection = newCollectionsByTitle[titleOfDestinationCollection] {
				// … then move the `Album` to the end of that `Collection`.
				os_signpost(.begin, log: log, name: "Move Album to matching new Collection")
				matchingNewCollection.unsafe_moveAlbumsToEnd_withoutDeleteOrReindexSourceCollections(
					with: [album.objectID],
					possiblyToSameCollection: false,
					via: context)
				os_signpost(.end, log: log, name: "Move Album to matching new Collection")
			} else if // Otherwise, if we already had a matching existing `Collection` …
				let matchingExistingCollection = existingCollectionsByTitle[titleOfDestinationCollection]?.first
			{
				// … then move the `Album` to the beginning of that `Collection`.
				os_signpost(.begin, log: log, name: "Move Album to matching existing Collection")
				matchingExistingCollection.unsafe_moveAlbumsToBeginning_withoutDeleteOrReindexSourceCollections(
					with: [album.objectID],
					possiblyToSameCollection: false,
					via: context)
				os_signpost(.end, log: log, name: "Move Album to matching existing Collection")
			} else {
				// Otherwise, create a matching `Collection`…
				let newCollection = Collection(
					index: indexOfSourceCollection + Int64(newCollectionsByTitle.count),
					before: collectionsToDisplace,
					title: titleOfDestinationCollection,
					context: context)
				newCollectionsByTitle[titleOfDestinationCollection] = newCollection
				
				// … and then move the `Album` to that `Collection`.
				os_signpost(.begin, log: log, name: "Move Album to new Collection")
				newCollection.unsafe_moveAlbumsToEnd_withoutDeleteOrReindexSourceCollections(
					with: [album.objectID],
					possiblyToSameCollection: false,
					via: context)
				os_signpost(.end, log: log, name: "Move Album to new Collection")
			}
		}
		
		// Create the `OrganizeAlbumsClipboard` to return.
		return OrganizeAlbumsClipboard(
			idsOfSubjectedAlbums: Set(albumsInOriginalContextToMaybeMove.map { $0.objectID }),
			idsOfSourceCollections: Set(albumsInOriginalContextToMaybeMove.map { $0.container!.objectID }),
			idsOfUnmovedAlbums: idsOfUnmovedAlbums,
			idsOfCollectionsContainingMovedAlbums: {
				let idsOfMovedAlbums = movedAlbumsInOriginalContext.map { $0.objectID }
				return Set(idsOfMovedAlbums.map {
					let albumInThisContext = context.object(with: $0) as! Album
					return albumInThisContext.container!.objectID
				})}(),
			delegate: delegateForClipboard)
	}
	
	func startMoving() {
		// Prepare a Collections view to present modally.
		let libraryNC = LibraryNC()
		guard
			let collectionsTVC = libraryNC.viewControllers.first as? CollectionsTVC,
			let albumsViewModel = viewModel as? AlbumsViewModel
		else { return }
		
		// Provide the extra data that the “move albums” sheet needs.
		let indexPathsToMove = albumsViewModel.sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: tableView.selectedIndexPaths)
		let albumsToMove = indexPathsToMove.map { albumsViewModel.albumNonNil(at: $0) }
		collectionsTVC.moveAlbumsClipboard = MoveAlbumsClipboard(
			albumsBeingMoved: albumsToMove,
			delegate: self)
		
		// Make the “move albums” sheet use a child managed object context, so that we can cancel without having to revert our changes.
		let childContext = NSManagedObjectContext(.mainQueue)
		childContext.parent = viewModel.context
		collectionsTVC.viewModel = CollectionsViewModel(
			context: childContext,
			prerowsInEachSection: [.createCollection])
		
		present(libraryNC, animated: true)
	}
}
