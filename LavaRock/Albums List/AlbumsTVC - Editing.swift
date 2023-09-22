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
	
	// MARK: - Move by artist
	
	func previewAutoMove() {
		// Prepare a Folders view to present modally.
		let nc = UINavigationController(
			rootViewController: UIStoryboard(name: "CollectionsTVC", bundle: nil)
				.instantiateInitialViewController()!
		)
		guard
			let collectionsTVC = nc.viewControllers.first as? CollectionsTVC,
			let albumsViewModel = viewModel as? AlbumsViewModel
		else { return }
		
		let selectedIndexPaths = tableView.selectedIndexPaths
		
		var subjectedRows: [Int] = selectedIndexPaths.map { $0.row }
		subjectedRows.sort()
		if subjectedRows.isEmpty {
			subjectedRows = albumsViewModel.rowsForAllItems()
		}
		let albumsInOriginalContextToMaybeMove = subjectedRows.map {
			albumsViewModel.albumNonNil(atRow: $0)
		}
		
		// Create a child managed object context to begin the changes in.
		let childContext = NSManagedObjectContext(.mainQueue)
		childContext.parent = viewModel.context
		
		let destinationCollections_ids = Self.autoMoveAndReturnDestinationCollectionIDs(
			albumsInOriginalContextToMaybeMove: albumsInOriginalContextToMaybeMove,
			via: childContext)
		let clipboard = OrganizeAlbumsClipboard(
			subjectedAlbums_ids: Set(albumsInOriginalContextToMaybeMove.map { $0.objectID }),
			destinationCollections_ids: destinationCollections_ids
		)
		
		collectionsTVC.navigationItem.prompt = clipboard.prompt
		collectionsTVC.willOrganizeAlbums = true
		
		// Make the “organize albums” sheet show the child context, but only after we present it.
		guard let oldFoldersViewModel = collectionsTVC.viewModel as? FoldersViewModel else { return }
		Task {
			await present__async(nc, animated: true)
			
			collectionsTVC.organizeAlbumsClipboard = clipboard
			collectionsTVC.willOrganizeAlbums = false
			
			// Similar to `reflectDatabase`.
			let _ = await collectionsTVC.setViewModelAndMoveAndDeselectRowsAndShouldContinue(
				firstReloading: {
					// We might have moved albums into existing folders. Fade in a highlight on those rows.
					let destinationRows = oldFoldersViewModel.rowsForAllItems().filter { oldRow in
						let collectionID = oldFoldersViewModel.folderNonNil(atRow: oldRow).objectID
						return clipboard.destinationCollections_ids.contains(collectionID)
					}
					return destinationRows.map { row in IndexPath(row: row, section: 0) }
				}(),
				FoldersViewModel(context: childContext),
				runningBeforeContinuation: {
					// Remove the now-playing marker from the source folder, if necessary.
					collectionsTVC.reflectPlayhead()
				}
			)
		}
	}
	private static func autoMoveAndReturnDestinationCollectionIDs(
		albumsInOriginalContextToMaybeMove: [Album],
		via context: NSManagedObjectContext
	) -> Set<NSManagedObjectID> {
		let log = OSLog.albumsView
		os_signpost(.begin, log: log, name: "Preview organizing Albums")
		defer {
			os_signpost(.end, log: log, name: "Preview organizing Albums")
		}
		
		let sourceCollection = albumsInOriginalContextToMaybeMove.first!.container!
		let sourceCollection_index = sourceCollection.index
		let sourceCollection_id = sourceCollection.objectID
		var createdDuringSession: [String: Collection] = [:]
		let existingFoldersByTitle: [String: [Collection]] = {
			let existingFolders = Collection.allFetched(sorted: true, context: context)
			return Dictionary(grouping: existingFolders) { $0.title! }
		}()
		
		albumsInOriginalContextToMaybeMove.reversed().forEach { album in
			// Similar to `newAlbumAndMaybeNewFolderMade`.
			
			let targetTitle = album.albumArtistFormatted()
			
			// If we’ve created a matching collection…
			if let createdMatch = createdDuringSession[targetTitle] {
				// …then move the album to the beginning of that collection.
				createdMatch.unsafe_InsertAlbums_WithoutDeleteOrReindexSources(
					atIndex: 0,
					albumIDs: [album.objectID],
					possiblyToSame: false,
					via: context)
			} else if
				// Otherwise, if there were already a matching collection before all this…
				let firstExistingMatch = existingFoldersByTitle[targetTitle]?.first(where: { existing in
					sourceCollection_id != existing.objectID
				})
			{
				// …then move the album to the beginning of that collection.
				firstExistingMatch.unsafe_InsertAlbums_WithoutDeleteOrReindexSources(
					atIndex: 0,
					albumIDs: [album.objectID],
					possiblyToSame: true,
					via: context)
			} else {
				// Last option: create a collection where the source collection was…
				let newMatch = context.newCollection(
					index: sourceCollection_index,
					title: targetTitle)
				createdDuringSession[targetTitle] = newMatch
				
				// …then put the album into it.
				newMatch.unsafe_InsertAlbums_WithoutDeleteOrReindexSources(
					atIndex: 0,
					albumIDs: [album.objectID],
					possiblyToSame: false,
					via: context)
			}
		}
		
		context.deleteEmptyCollections()
		
		let subjectedAlbums_ids = albumsInOriginalContextToMaybeMove.map { $0.objectID }
		let subjectedAlbums = subjectedAlbums_ids.map {
			context.object(with: $0) as! Album
		}
		let destinationCollections_ids = subjectedAlbums.map {
			$0.container!.objectID
		}
		return Set(destinationCollections_ids)
	}
	
	// MARK: - Move to stack
	
	func startMoving() {
		// Prepare a Collections view to present modally.
		let nc = UINavigationController(
			rootViewController: UIStoryboard(name: "CollectionsTVC", bundle: nil)
				.instantiateInitialViewController()!
		)
		guard
			let collectionsTVC = nc.viewControllers.first as? CollectionsTVC,
			let selfVM = viewModel as? AlbumsViewModel
		else { return }
		
		// Configure the `CollectionsTVC`.
		collectionsTVC.moveAlbumsClipboard = MoveAlbumsClipboard(albumsBeingMoved: {
			var subjectedRows: [Int] = tableView.selectedIndexPaths.map { $0.row }
			subjectedRows.sort()
			if subjectedRows.isEmpty {
				subjectedRows = selfVM.rowsForAllItems()
			}
			return subjectedRows.map {
				selfVM.albumNonNil(atRow: $0)
			}
		}())
		collectionsTVC.viewModel = FoldersViewModel(context: {
			let childContext = NSManagedObjectContext(.mainQueue)
			childContext.parent = viewModel.context
			return childContext
		}())
		
		present(nc, animated: true)
	}
}
