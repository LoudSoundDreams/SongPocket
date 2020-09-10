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
	
	@IBAction func startMovingAlbums(_ sender: UIBarButtonItem) {
		
		// Prepare a Collections view to present modally.
		
		let modalCollectionsNC = storyboard!.instantiateViewController(withIdentifier: "Collections NC") as! UINavigationController
		let modalCollectionsTVC = modalCollectionsNC.viewControllers.first as! CollectionsTVC
		
		// Initialize an AlbumMoverClipboard for the modal Collections view.
		
		let idOfSourceCollection = containerOfData!.objectID
		
		// Note the albums to move, and to not move.
		
		var idsOfAlbumsToMove = [NSManagedObjectID]()
		var idsOfAlbumsToNotMove = [NSManagedObjectID]()
		
		if let selectedIndexPaths = tableView.indexPathsForSelectedRows { // If any rows are selected.
			for indexPath in indexPathsEnumeratedIn(section: 0, firstRow: 0, lastRow: tableView.numberOfRows(inSection: 0) - 1) {
				let album = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as! Album
				if selectedIndexPaths.contains(indexPath) { // If the row is selected.
					idsOfAlbumsToMove.append(album.objectID)
				} else { // The row is not selected.
					idsOfAlbumsToNotMove.append(album.objectID)
				}
			}
		} else { // No rows are selected.
			for album in indexedLibraryItems {
				idsOfAlbumsToMove.append(album.objectID)
			}
		}
		
		modalCollectionsTVC.albumMoverClipboard = AlbumMoverClipboard(
			idOfCollectionThatAlbumsAreBeingMovedOutOf: idOfSourceCollection,
			idsOfAlbumsBeingMoved: idsOfAlbumsToMove,
			idsOfAlbumsNotBeingMoved: idsOfAlbumsToNotMove
		)
		
		// Make the destination operate in a child managed object context, so that you can cancel without saving your changes.
		
		let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		childManagedObjectContext.parent = managedObjectContext
		childManagedObjectContext.automaticallyMergesChangesFromParent = true
		
		modalCollectionsTVC.managedObjectContext = childManagedObjectContext
		
		present(modalCollectionsNC, animated: true, completion: nil)
		
	}
	
	// MARK: - Ending Moving Albums
	
	@IBAction func moveAlbumsHere(_ sender: UIBarButtonItem) {
		
		guard
			let albumMoverClipboard = albumMoverClipboard,
			albumMoverClipboard.didAlreadyCommitMoveAlbums == false
		else { return }
		
		// We shouldn't be moving albums to this collection if they're already here.
		for albumInCollectionToMoveTo in indexedLibraryItems {
			if albumMoverClipboard.idsOfAlbumsBeingMoved.contains(albumInCollectionToMoveTo.objectID) {
				return
			}
		}
		
		albumMoverClipboard.didAlreadyCommitMoveAlbums = true // Without this, if you tap the "Move Here" button more than once, the app will crash when it tries to unwind from the "move albums" sheet.
		// You won't obviate this hack even if you put as much of this logic as possible onto a background queue to get to the animation sooner. The animation *is* the slow part. If I set a breakpoint before the animation, I can't even tap the "Move Here" button twice before hitting that breakpoint.
		// Another solution would be to set moveAlbumsHereButton.isEnabled = false, but that looks weird and non-standard, and it confuses VoiceOver.
		
		if indexedLibraryItems.isEmpty {
			newCollectionDetector!.shouldDetectNewCollectionsOnNextViewWillAppear = true
		}
		
		// Get the albums to move, and to not move.
		var albumsToMove = [Album]()
		for albumID in albumMoverClipboard.idsOfAlbumsBeingMoved {
			albumsToMove.append(managedObjectContext.object(with: albumID) as! Album)
		}
		var albumsToNotMove = [Album]()
		for albumID in albumMoverClipboard.idsOfAlbumsNotBeingMoved {
			albumsToNotMove.append(managedObjectContext.object(with: albumID) as! Album)
		}
		
		// Apply the changes.
		
		// Update the indexes of the albums we aren't moving, within their collection.
		// Almost identical to the property observer for indexedLibraryItems.
		for index in 0..<albumsToNotMove.count {
			albumsToNotMove[index].setValue(index, forKey: "index")
		}
		
		func saveParentManagedObjectContext() {
			do {
				try managedObjectContext.parent!.save()
			} catch {
				fatalError("Crashed while trying to commit changes, just before dismissing the “move albums” sheet: \(error)")
			}
		}
		
		for index in 0..<albumsToMove.count {
			let album = albumsToMove[index]
			album.container = containerOfData as? Collection
			indexedLibraryItems.insert(album, at: index)
		}
		managedObjectContext.tryToSave()
		saveParentManagedObjectContext()
		
		// Update the table view.
		let indexPathsToInsert = indexPathsEnumeratedIn(section: 0, firstRow: 0, lastRow: albumsToMove.count - 1)
		tableView.performBatchUpdates( {
				tableView.insertRows(at: indexPathsToInsert, with: .middle)
		}, completion: { _ in
			self.performSegue(withIdentifier: "Moved Albums", sender: self)
		})
		
	}
	
}
