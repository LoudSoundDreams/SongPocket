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
	func previewAutoMove() {
		// Prepare a Folders view to present modally.
		let nc = UINavigationController(
			rootViewController: UIStoryboard(name: "FoldersTVC", bundle: nil)
				.instantiateInitialViewController()!
		)
		guard
			let foldersTVC = nc.viewControllers.first as? FoldersTVC,
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
		
		// Move the `Album`s it makes sense to move, and save the object IDs of the rest, to keep them selected.
		let clipboard: OrganizeAlbumsClipboard = {
			let report = Self.autoMoveAndReturnReport(
				albumsInOriginalContextToMaybeMove: albumsInOriginalContextToMaybeMove,
				via: childContext)
			return OrganizeAlbumsClipboard(
				ids_subjectedAlbums: Set(albumsInOriginalContextToMaybeMove.map { $0.objectID }),
				ids_sourceCollections: Set(albumsInOriginalContextToMaybeMove.map { $0.container!.objectID }),
				ids_unmovedAlbums: report.ids_unmovedAlbums,
				ids_collectionsContainingMovedAlbums: report.ids_collectionsContainingMovedAlbums,
				delegate: self
			)
		}()
		ids_albumsToKeepSelected = { () -> Set<NSManagedObjectID> in
			let selectedAlbums = selectedIndexPaths.map {
				albumsViewModel.albumNonNil(atRow: $0.row)
			}
			return Set(selectedAlbums.compactMap {
				let selectedAlbumID = $0.objectID
				if clipboard.ids_unmovedAlbums.contains(selectedAlbumID) {
					return selectedAlbumID
				} else {
					return nil
				}
			})
		}()
		
		foldersTVC.willOrganizeAlbumsStickyNote = WillOrganizeAlbumsStickyNote(
			prompt: clipboard.prompt,
			ids_sourceCollections: clipboard.ids_sourceCollections)
		
		// Make the “organize albums” sheet show the child context, but only after we present it.
		guard let oldFoldersViewModel = foldersTVC.viewModel as? FoldersViewModel else { return }
		Task {
			await present__async(nc, animated: true)
			
			foldersTVC.organizeAlbumsClipboard = clipboard
			foldersTVC.willOrganizeAlbumsStickyNote = nil
			
			// Similar to `reflectDatabase`.
			let _ = await foldersTVC.setViewModelAndMoveAndDeselectRowsAndShouldContinue(
				firstReloading: {
					// We might have moved albums into any existing folder other than the source. If so, fade in a highlight on those rows.
					let oldRows_ContainingMovedAlbums = oldFoldersViewModel.rowsForAllItems().filter { oldRow in
						let collectionID = oldFoldersViewModel.folderNonNil(atRow: oldRow).objectID
						return clipboard.ids_collectionsContainingMovedAlbums.contains(collectionID)
					}
					return oldRows_ContainingMovedAlbums.map { row in IndexPath(row: row, section: 0) }
				}(),
				FoldersViewModel(context: childContext),
				runningBeforeContinuation: {
					// Remove the now-playing marker from the source folder, if necessary.
					foldersTVC.reflectPlayhead()
				}
			)
		}
	}
	private static func autoMoveAndReturnReport(
		albumsInOriginalContextToMaybeMove: [Album],
		via context: NSManagedObjectContext
	) -> (
		ids_unmovedAlbums: Set<NSManagedObjectID>,
		ids_collectionsContainingMovedAlbums: Set<NSManagedObjectID>
	) {
		let log = OSLog.albumsView
		os_signpost(.begin, log: log, name: "Preview organizing Albums")
		defer {
			os_signpost(.end, log: log, name: "Preview organizing Albums")
		}
		
		// If an album is already in a folder with a title that matches its album artist, then leave it there.
		// Otherwise, move the album to the first folder with a matching title.
		// If there is no matching folder, then create one.
		// Put new folders above the source folder, in the order that the album artists first appear among the albums we’re moving.
		
		// Results
		var movedAlbumsInOriginalContext: Set<Album> = []
		var ids_unmovedAlbums: Set<NSManagedObjectID> = []
		
		// Work notes
		let indexOfSourceFolder = albumsInOriginalContextToMaybeMove.first!.container!.index
		let toDisplace: [Collection] = {
			let predicate = NSPredicate(
				format: "index >= %lld",
				indexOfSourceFolder)
			return Collection.allFetched(
				sorted: true,
				predicate: predicate,
				context: context)
		}()
		var newFoldersByTitle: [String: Collection] = [:]
		let existingFoldersByTitle: [String: [Collection]] = {
			let existingFolders = Collection.allFetched(sorted: true, context: context)
			return Dictionary(grouping: existingFolders) { $0.title! }
		}()
		
		albumsInOriginalContextToMaybeMove.forEach { album in
			// Similar to `newAlbumAndMaybeNewFolderMade`.
			
			let titleOfDestination = album.albumArtistFormatted()
			
			guard album.container!.title != titleOfDestination else {
				ids_unmovedAlbums.insert(album.objectID)
				return
			}
			
			movedAlbumsInOriginalContext.insert(album)
			
			// If we’ve created a matching new folder…
			if let matchingNewFolder = newFoldersByTitle[titleOfDestination] {
				// …then move the album to the end of that folder.
				matchingNewFolder.unsafe_moveAlbumsToEnd_withoutDeleteOrReindexSources(
					with: [album.objectID],
					possiblyToSame: false,
					via: context)
			} else if // Otherwise, if we already had a matching existing folder…
				let matchingExisting = existingFoldersByTitle[titleOfDestination]?.first
			{
				// …then move the album to the beginning of that folder.
				matchingExisting.unsafe_moveAlbumsToBeginning_withoutDeleteOrReindexSources(
					with: [album.objectID],
					possiblyToSame: false,
					via: context)
			} else {
				// Otherwise, create a matching folder…
				let newFolder = Collection(
					index: indexOfSourceFolder + Int64(newFoldersByTitle.count),
					before: toDisplace,
					title: titleOfDestination,
					context: context)
				newFoldersByTitle[titleOfDestination] = newFolder
				
				// …and then move the album to that folder.
				newFolder.unsafe_moveAlbumsToEnd_withoutDeleteOrReindexSources(
					with: [album.objectID],
					possiblyToSame: false,
					via: context)
			}
		}
		
		return (
			ids_unmovedAlbums: ids_unmovedAlbums,
			ids_collectionsContainingMovedAlbums: {
				let ids_movedAlbums = movedAlbumsInOriginalContext.map { $0.objectID }
				return Set(ids_movedAlbums.map {
					let albumInThisContext = context.object(with: $0) as! Album
					return albumInThisContext.container!.objectID
				})
			}()
		)
	}
	
	func startMoving() {
		// Prepare a Folders view to present modally.
		let nc = UINavigationController(
			rootViewController: UIStoryboard(name: "FoldersTVC", bundle: nil)
				.instantiateInitialViewController()!
		)
		guard
			let foldersTVC = nc.viewControllers.first as? FoldersTVC,
			let selfVM = viewModel as? AlbumsViewModel
		else { return }
		
		// Configure the `FoldersTVC`.
		foldersTVC.moveAlbumsClipboard = MoveAlbumsClipboard(
			albumsBeingMoved: {
				var subjectedRows: [Int] = tableView.selectedIndexPaths.map { $0.row }
				subjectedRows.sort()
				if subjectedRows.isEmpty {
					subjectedRows = selfVM.rowsForAllItems()
				}
				return subjectedRows.map {
					selfVM.albumNonNil(atRow: $0)
				}
			}(),
			delegate: self
		)
		foldersTVC.viewModel = FoldersViewModel(
			context: {
				let childContext = NSManagedObjectContext(.mainQueue)
				childContext.parent = viewModel.context
				return childContext
			}()
		)
		
		present(nc, animated: true)
	}
}
