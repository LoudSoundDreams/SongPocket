//
//  AlbumsTVC - “Moving Albums” Mode.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// MARK: - Ending Moving
	
	final func moveAlbumsHere() {
		
		guard
			viewModel.groups.count == 1,
			let viewModel = viewModel as? AlbumsViewModel,
			let albumMoverClipboard = albumMoverClipboard,
			!albumMoverClipboard.didAlreadyCommitMoveAlbums // Without this, if you tap the "Move Here" button more than once, the app will crash.
				// You won't obviate this hack even if you put as much of this logic as possible onto a background queue to get to the animation sooner. The animation *is* the slow part. If I set a breakpoint before the animation, I can't even tap the "Move Here" button twice before hitting that breakpoint.
		else { return }
		
		albumMoverClipboard.didAlreadyCommitMoveAlbums = true
		
		// Make a new data source.
		let indexOfGroup = 0 //
		let newItems = viewModel.itemsAfterMovingHere(
			albumsWith: albumMoverClipboard.idsOfAlbumsBeingMoved,
			indexOfGroup: indexOfGroup, //
			context: context)
		
		// Update the table view.
		setItemsAndRefresh(
			newItems: newItems,
			section: viewModel.numberOfSectionsAboveLibraryItems
		) {
			self.context.tryToSave()
			self.context.parent!.tryToSave() // Save the main context now, even though we haven't exited editing mode, because if you moved all the Albums out of a Collection, we'll close the Collection and exit editing mode shortly.
			
			NotificationCenter.default.post(
				Notification(name: .LRDidMoveAlbums)
			)
			
			self.dismiss(animated: true)
			albumMoverClipboard.delegate?.didMoveAlbumsThenCommitDismiss()
		}
		
	}
	
}
