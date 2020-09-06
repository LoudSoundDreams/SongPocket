//
//  “Moving Albums” Mode (AlbumsTVC).swift
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
		
		// Initialize a MoveAlbumsClipboard for the modal Collections view.
		
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
		
		modalCollectionsTVC.moveAlbumsClipboard = MoveAlbumsClipboard(
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
		
		guard let moveAlbumsClipboard = moveAlbumsClipboard else {
			return
		}
		
		moveAlbumsHereButton.isEnabled = false // Without this, if you tap the "Move Here" button more than once, the app will crash when it tries to unwind from the "move albums" sheet.
		// You won't obviate this hack even if you put as much of this logic as possible onto a background queue to get to the animation sooner. The animation *is* the slow part. If I set a breakpoint before the animation, I can't even tap the "Move Here" button twice before hitting that breakpoint.
		// Unfortunately, disabling a button after you tap it looks weird and non-standard, and TO DO: it confuses VoiceOver.
		
		if indexedLibraryItems.isEmpty {
			newCollectionDetector!.shouldDetectNewCollectionsOnNextViewWillAppear = true
		}
		
		// Get the albums to move, and to not move.
		var albumsToMove = [Album]()
		for albumID in moveAlbumsClipboard.idsOfAlbumsBeingMoved {
			albumsToMove.append(managedObjectContext.object(with: albumID) as! Album)
		}
		var albumsToNotMove = [Album]()
		for albumID in moveAlbumsClipboard.idsOfAlbumsNotBeingMoved {
			albumsToNotMove.append(managedObjectContext.object(with: albumID) as! Album)
		}
		
		// Find out if we're moving albums to the collection they were already in.
		// If so, we'll use the "move rows to top" logic.
		let isMovingToSameCollection = indexedLibraryItems.contains(albumsToMove[0])
		
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
		
		if !isMovingToSameCollection {
			for index in 0..<albumsToMove.count {
				let album = albumsToMove[index]
				album.container = containerOfData as? Collection
				indexedLibraryItems.insert(album, at: index)
			}
			managedObjectContext.tryToSave()
			saveParentManagedObjectContext()
		}
		
		// If we're moving albums to the collection they're already in, prepare for "move rows to top".
		var indexPathsToMoveToTop = [IndexPath]()
		if isMovingToSameCollection {
			for album in albumsToMove {
				let index = indexedLibraryItems.firstIndex(of: album)
				guard index != nil else {
					fatalError("It looks like we’re moving albums to the collection they’re already in, but one of the albums we’re moving isn’t here.")
				}
				indexPathsToMoveToTop.append(IndexPath(row: index!, section: 0))
			}
		}
		
		// Update the table view.
		tableView.performBatchUpdates( {
			if isMovingToSameCollection {
				// You need to do this in performBatchUpdates so that the sheet dismisses after the rows finish animating.
				moveItemsUp(from: indexPathsToMoveToTop, to: IndexPath(row: 0, section: 0))
				managedObjectContext.tryToSave()
				saveParentManagedObjectContext()
			} else {
				let indexPaths = indexPathsEnumeratedIn(section: 0, firstRow: 0, lastRow: albumsToMove.count - 1)
				tableView.insertRows(at: indexPaths, with: .middle)
			}
			
		}, completion: { _ in
			self.performSegue(withIdentifier: "Moved Albums", sender: self)
		})
		
	}
	
}
