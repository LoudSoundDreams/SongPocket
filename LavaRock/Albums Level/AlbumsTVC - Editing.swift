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
		let libraryNC = LibraryNC(rootStoryboardName: "FoldersTVC")
		guard
			let foldersTVC = libraryNC.viewControllers.first as? FoldersTVC,
			let albumsViewModel = viewModel as? AlbumsViewModel
		else { return }
		
		let selectedIndexPaths = tableView.selectedIndexPaths
		
		var subjected: [IndexPath] = selectedIndexPaths
		subjected.sort()
		if subjected.isEmpty {
			subjected = albumsViewModel.indexPathsForAllItems()
		}
		let albumsInOriginalContextToMaybeMove = subjected.map {
			albumsViewModel.albumNonNil(at: $0)
		}
		
		// Create a child managed object context to begin the changes in.
		let childContext = NSManagedObjectContext(.mainQueue)
		childContext.parent = viewModel.context
		
		// Move the `Album`s it makes sense to move, and save the object IDs of the rest, to keep them selected.
		let clipboard = Self.autoMoveAndReturnClipboard(
			albumsInOriginalContextToMaybeMove: albumsInOriginalContextToMaybeMove,
			via: childContext,
			delegateForClipboard: self
		)
		let selectedAlbums = selectedIndexPaths.map { albumsViewModel.albumNonNil(at: $0) }
		idsOfAlbumsToKeepSelected = Set(selectedAlbums.compactMap {
			let selectedAlbumID = $0.objectID
			if clipboard.idsOfUnmovedAlbums.contains(selectedAlbumID) {
				return selectedAlbumID
			} else {
				return nil
			}
		})
		
		foldersTVC.willOrganizeAlbumsStickyNote = WillOrganizeAlbumsStickyNote(
			prompt: clipboard.prompt,
			idsOfSourceCollections: clipboard.idsOfSourceCollections)
		
		// Make the “organize albums” sheet show the child context, but only after we present it.
		guard let oldFoldersViewModel = foldersTVC.viewModel as? FoldersViewModel else { return }
		Task {
			await present__async(libraryNC, animated: true)
			
			foldersTVC.organizeAlbumsClipboard = clipboard
			foldersTVC.willOrganizeAlbumsStickyNote = nil
			
			let previewOfChanges = FoldersViewModel(
				context: childContext,
				prerowsInEachSection: [])
			// We might have moved albums into any existing folder other than the source. If so, fade in a highlight on those rows.
			let originalIndexPathsOfFoldersContainingMovedAlbums = oldFoldersViewModel.indexPathsForAllItems().filter {
				let collectionID = oldFoldersViewModel.folderNonNil(at: $0).objectID
				return clipboard.idsOfCollectionsContainingMovedAlbums.contains(collectionID)
			}
			
			// Similar to `reflectDatabase`.
			let _ = await foldersTVC.setViewModelAndMoveAndDeselectRowsAndShouldContinue(
				firstReloading: originalIndexPathsOfFoldersContainingMovedAlbums,
				previewOfChanges,
				runningBeforeContinuation: {
					// Remove the now-playing marker from the source folder, if necessary.
					foldersTVC.reflectPlayhead()
				}
			)
		}
	}
	
	private static func autoMoveAndReturnClipboard(
		albumsInOriginalContextToMaybeMove: [Album],
		via context: NSManagedObjectContext,
		delegateForClipboard: OrganizeAlbumsDelegate
	) -> OrganizeAlbumsClipboard {
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
		var idsOfUnmovedAlbums: Set<NSManagedObjectID> = []
		
		// Work notes
		let indexOfSourceFolder = albumsInOriginalContextToMaybeMove.first!.container!.index
		let toDisplace: [Collection] = {
			let predicate = NSPredicate(
				format: "index >= %lld",
				indexOfSourceFolder)
			return Collection.allFetched(
				ordered: true,
				predicate: predicate,
				via: context)
		}()
		var newFoldersByTitle: [String: Collection] = [:]
		let existingFoldersByTitle: [String: [Collection]] = {
			let existingFolders = Collection.allFetched(ordered: true, via: context)
			return Dictionary(grouping: existingFolders) { $0.title! }
		}()
		
		albumsInOriginalContextToMaybeMove.forEach { album in
			// Similar to `newAlbumAndMaybeNewFolderMade`.
			
			let titleOfDestination = album.albumArtistFormatted()
			
			guard album.container!.title != titleOfDestination else {
				idsOfUnmovedAlbums.insert(album.objectID)
				return
			}
			
			movedAlbumsInOriginalContext.insert(album)
			
			// If we’ve created a matching new folder…
			if let matchingNewFolder = newFoldersByTitle[titleOfDestination] {
				// …then move the album to the end of that folder.
				os_signpost(.begin, log: log, name: "Move album to matching new folder")
				matchingNewFolder.unsafe_moveAlbumsToEnd_withoutDeleteOrReindexSources(
					with: [album.objectID],
					possiblyToSame: false,
					via: context)
				os_signpost(.end, log: log, name: "Move album to matching new folder")
			} else if // Otherwise, if we already had a matching existing folder…
				let matchingExisting = existingFoldersByTitle[titleOfDestination]?.first
			{
				// …then move the album to the beginning of that folder.
				os_signpost(.begin, log: log, name: "Move album to matching existing folder")
				matchingExisting.unsafe_moveAlbumsToBeginning_withoutDeleteOrReindexSources(
					with: [album.objectID],
					possiblyToSame: false,
					via: context)
				os_signpost(.end, log: log, name: "Move album to matching existing folder")
			} else {
				// Otherwise, create a matching folder…
				let newFolder = Collection(
					index: indexOfSourceFolder + Int64(newFoldersByTitle.count),
					before: toDisplace,
					title: titleOfDestination,
					context: context)
				newFoldersByTitle[titleOfDestination] = newFolder
				
				// …and then move the album to that folder.
				os_signpost(.begin, log: log, name: "Move album to new folder")
				newFolder.unsafe_moveAlbumsToEnd_withoutDeleteOrReindexSources(
					with: [album.objectID],
					possiblyToSame: false,
					via: context)
				os_signpost(.end, log: log, name: "Move album to new folder")
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
		// Prepare a Folders view to present modally.
		let libraryNC = LibraryNC(rootStoryboardName: "FoldersTVC")
		guard
			let foldersTVC = libraryNC.viewControllers.first as? FoldersTVC,
			let selfVM = viewModel as? AlbumsViewModel
		else { return }
		
		// Configure the `FoldersTVC`.
		foldersTVC.moveAlbumsClipboard = MoveAlbumsClipboard(
			albumsBeingMoved: {
				var subjected: [IndexPath] = tableView.selectedIndexPaths
				subjected.sort()
				if subjected.isEmpty {
					subjected = selfVM.indexPathsForAllItems()
				}
				return subjected.map {
					selfVM.albumNonNil(at: $0)
				}
			}(),
			delegate: self
		)
		foldersTVC.viewModel = FoldersViewModel(
			context: {
				let childContext = NSManagedObjectContext(.mainQueue)
				childContext.parent = viewModel.context
				return childContext
			}(),
			prerowsInEachSection: [.createFolder]
		)
		
		present(libraryNC, animated: true)
	}
}
