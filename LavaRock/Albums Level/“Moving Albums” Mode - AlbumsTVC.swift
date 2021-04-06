//
//  “Moving Albums” Mode - AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// MARK: - Starting Moving Albums
	
	@objc func startMovingAlbums() {
		
		// Prepare a Collections view to present modally.
		
		guard
			let modalCollectionsNC = storyboard!.instantiateViewController(withIdentifier: "Collections NC") as? UINavigationController,
			let modalCollectionsTVC = modalCollectionsNC.viewControllers.first as? CollectionsTVC
		else {
			return
		}
		
		// Initialize an AlbumMoverClipboard for the modal Collections view.
		
		guard let idOfSourceCollection = sectionOfLibraryItems.container?.objectID else { return }
		
		// Note the Albums to move, and to not move.
		
		var idsOfAlbumsToMove = [NSManagedObjectID]()
		var idsOfAlbumsToNotMove = [NSManagedObjectID]()
		
		if let selectedIndexPaths = tableView.indexPathsForSelectedRows { // If any rows are selected.
			for indexPath in tableView.indexPathsForRowsIn(
				section: 0,
				firstRow: numberOfRowsAboveLibraryItems)
			{
				let album = libraryItem(for: indexPath) as! Album
				if selectedIndexPaths.contains(indexPath) { // If the row is selected.
					idsOfAlbumsToMove.append(album.objectID)
				} else { // The row is not selected.
					idsOfAlbumsToNotMove.append(album.objectID)
				}
			}
		} else { // No rows are selected.
			for album in sectionOfLibraryItems.items {
				idsOfAlbumsToMove.append(album.objectID)
			}
		}
		
		modalCollectionsTVC.albumMoverClipboard = AlbumMoverClipboard(
			idOfCollectionThatAlbumsAreBeingMovedOutOf: idOfSourceCollection,
			idsOfAlbumsBeingMoved: idsOfAlbumsToMove,
			idsOfAlbumsNotBeingMoved: idsOfAlbumsToNotMove,
			delegate: self
		)
		
		// Make the destination operate in a child managed object context, so that you can cancel without saving your changes.
		let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		childManagedObjectContext.parent = managedObjectContext
		modalCollectionsTVC.managedObjectContext = childManagedObjectContext
		
		present(modalCollectionsNC, animated: true, completion: nil)
		
	}
	
	// MARK: - Ending Moving Albums
	
	@IBAction func moveAlbumsHere(_ sender: UIBarButtonItem) {
		
		guard
			let albumMoverClipboard = albumMoverClipboard,
			!albumMoverClipboard.didAlreadyCommitMoveAlbums
		else { return }
		
		// We shouldn't be moving Albums to this Collection if they're already here.
		for albumInCollectionToMoveTo in sectionOfLibraryItems.items {
			if albumMoverClipboard.idsOfAlbumsBeingMoved.contains(albumInCollectionToMoveTo.objectID) {
				return
			}
		}
		
		albumMoverClipboard.didAlreadyCommitMoveAlbums = true // Without this, if you tap the "Move Here" button more than once, the app will crash when it tries to unwind from the "move Albums" sheet.
		// You won't obviate this hack even if you put as much of this logic as possible onto a background queue to get to the animation sooner. The animation *is* the slow part. If I set a breakpoint before the animation, I can't even tap the "Move Here" button twice before hitting that breakpoint.
		
		// Get the Albums to move, and to not move.
		var albumsToMove = [Album]()
		for albumID in albumMoverClipboard.idsOfAlbumsBeingMoved {
			albumsToMove.append(managedObjectContext.object(with: albumID) as! Album)
		}
		var albumsToNotMove = [Album]()
		for albumID in albumMoverClipboard.idsOfAlbumsNotBeingMoved {
			albumsToNotMove.append(managedObjectContext.object(with: albumID) as! Album)
		}
		
		// Apply the changes.
		
		// Update the indexes of the Albums we aren't moving, within their Collection.
		// Almost identical to the property observer for sectionOfLibraryItems.items.
		for index in 0 ..< albumsToNotMove.count {
			albumsToNotMove[index].index = Int64(index)
		}
		
		let sourceCollection = albumsToMove.first!.container!
		// Move the Albums we're moving.
		for index in 0 ..< albumsToMove.count {
			let album = albumsToMove[index]
			album.container = sectionOfLibraryItems.container as? Collection
			sectionOfLibraryItems.items.insert(album, at: index)
		}
		// If we moved all the Albums out of the Collection they used to be in, then delete that Collection.
		if
			sourceCollection.contents == nil || sourceCollection.contents?.count == 0
		{
			managedObjectContext.delete(sourceCollection)
			let collectionsFetchRequest: NSFetchRequest<Collection> = Collection.fetchRequest()
			collectionsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
			let collections = managedObjectContext.objectsFetched(for: collectionsFetchRequest)
			// Almost identical to the property observer for sectionOfLibraryItems.items.
			for index in 0 ..< collections.count {
				collections[index].index = Int64(index)
			}
		}
		
		managedObjectContext.tryToSaveSynchronously()
		guard let mainManagedObjectContext = managedObjectContext.parent else {
			fatalError("Couldn’t access the main managed object context to save changes, just before dismissing the “move Albums” sheet.")
		}
		mainManagedObjectContext.tryToSave()
		
		// Update the table view.
		let indexPathsToInsert = tableView.indexPathsForRowsIn(
			section: 0,
			firstRow: 0,
			lastRow: albumsToMove.count - 1)
		tableView.performBatchUpdates( {
				tableView.insertRows(at: indexPathsToInsert, with: .middle)
		}, completion: { _ in
			self.dismiss(animated: true, completion: { albumMoverClipboard.delegate?.didMoveAlbumsThenFinishDismiss()
			})
			albumMoverClipboard.delegate?.didMoveAlbumsThenCommitDismiss()
		})
		
	}
	
}
