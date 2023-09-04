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
				subjectedAlbums_ids: Set(albumsInOriginalContextToMaybeMove.map { $0.objectID }),
				unmovedAlbums_ids: report.unmovedAlbums_ids,
				containingMoved_ids: report.containingMoved_ids
			)
		}()
		ids_albumsToKeepSelected = { () -> Set<NSManagedObjectID> in
			let selectedAlbums = selectedIndexPaths.map {
				albumsViewModel.albumNonNil(atRow: $0.row)
			}
			return Set(selectedAlbums.compactMap {
				let selectedAlbumID = $0.objectID
				if clipboard.unmovedAlbums_ids.contains(selectedAlbumID) {
					return selectedAlbumID
				} else {
					return nil
				}
			})
		}()
		
		foldersTVC.navigationItem.prompt = clipboard.prompt
		foldersTVC.willOrganizeAlbums = true
		
		// Make the “organize albums” sheet show the child context, but only after we present it.
		guard let oldFoldersViewModel = foldersTVC.viewModel as? FoldersViewModel else { return }
		Task {
			await present__async(nc, animated: true)
			
			foldersTVC.organizeAlbumsClipboard = clipboard
			foldersTVC.willOrganizeAlbums = false
			
			// Similar to `reflectDatabase`.
			let _ = await foldersTVC.setViewModelAndMoveAndDeselectRowsAndShouldContinue(
				firstReloading: {
					// We might have moved albums into existing folders. Fade in a highlight on those rows.
					let destinationRows = oldFoldersViewModel.rowsForAllItems().filter { oldRow in
						let collectionID = oldFoldersViewModel.folderNonNil(atRow: oldRow).objectID
						return clipboard.containingMoved_ids.contains(collectionID)
					}
					return destinationRows.map { row in IndexPath(row: row, section: 0) }
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
		unmovedAlbums_ids: Set<NSManagedObjectID>,
		containingMoved_ids: Set<NSManagedObjectID>
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
		var unmovedAlbums_ids: Set<NSManagedObjectID> = []
		var movedAlbums_ids: Set<NSManagedObjectID> = []
		
		// Work notes
		let indexOfSourceFolder = albumsInOriginalContextToMaybeMove.first!.container!.index
		var createdDuringSession: [String: Collection] = [:]
		let existingFoldersByTitle: [String: [Collection]] = {
			let existingFolders = Collection.allFetched(sorted: true, context: context)
			return Dictionary(grouping: existingFolders) { $0.title! }
		}()
		
		albumsInOriginalContextToMaybeMove.reversed().forEach { album in
			// Similar to `newAlbumAndMaybeNewFolderMade`.
			
			let targetTitle = album.albumArtistFormatted()
			
			guard album.container!.title != targetTitle else {
				unmovedAlbums_ids.insert(album.objectID)
				return
			}
			
			movedAlbums_ids.insert(album.objectID)
			
			// If we’ve created a matching stack…
			if let createdMatch = createdDuringSession[targetTitle] {
				// …then move the album to the top of that stack.
				createdMatch.unsafe_InsertAlbums_WithoutDeleteOrReindexSources(
					atIndex: 0,
					albumIDs: [album.objectID],
					possiblyToSame: false,
					via: context)
			} else if
				// Otherwise, if there were already a matching stack before all this…
				let existingMatch = existingFoldersByTitle[targetTitle]?.first
			{
				// …then move the album to the top of that stack.
				existingMatch.unsafe_InsertAlbums_WithoutDeleteOrReindexSources(
					atIndex: 0,
					albumIDs: [album.objectID],
					possiblyToSame: false,
					via: context)
			} else {
				// Otherwise, create a matching stack where the source stack was…
				let newMatch = context.newCollection(
					index: indexOfSourceFolder,
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
		
		return (
			unmovedAlbums_ids: unmovedAlbums_ids,
			containingMoved_ids: {
				return Set(movedAlbums_ids.map {
					let albumInThisContext = context.object(with: $0) as! Album
					return albumInThisContext.container!.objectID
				})
			}()
		)
	}
	
	// MARK: - Move to stack
	
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
		foldersTVC.moveAlbumsClipboard = MoveAlbumsClipboard(albumsBeingMoved: {
			var subjectedRows: [Int] = tableView.selectedIndexPaths.map { $0.row }
			subjectedRows.sort()
			if subjectedRows.isEmpty {
				subjectedRows = selfVM.rowsForAllItems()
			}
			return subjectedRows.map {
				selfVM.albumNonNil(atRow: $0)
			}
		}())
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
