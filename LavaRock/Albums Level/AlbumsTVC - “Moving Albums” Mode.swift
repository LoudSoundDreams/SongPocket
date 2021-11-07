//
//  AlbumsTVC - “Moving Albums” Mode.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	final func moveAlbumsHere() {
		
		guard
			let albumsViewModel = viewModel as? AlbumsViewModel,
			let albumMoverClipboard = albumMoverClipboard,
			!albumMoverClipboard.didAlreadyCommitMoveAlbums // Without this, if you tap the "Move Here" button more than once, the app crashes. You can tap that button more than once because it receives events during table view updates, which run asynchronously.
		else { return }
		
		albumMoverClipboard.didAlreadyCommitMoveAlbums = true
		
		// Make a new data source.
		let newViewModel = albumsViewModel.updatedAfterMovingIntoOnlyGroup(
			albumsWith: albumMoverClipboard.idsOfAlbumsBeingMoved)
		
		// Update the data source and table view.
		setViewModelAndMoveRows(newViewModel) {
			self.viewModel.context.tryToSave()
			self.viewModel.context.parent!.tryToSave() // Save the main context now, even though we haven't exited editing mode, because if you moved all the Albums out of a Collection, we'll close the Collection and exit editing mode shortly.
			
			NotificationCenter.default.post(
				Notification(name: .LRDidMoveAlbums)
			)
			
			self.dismiss(animated: true)
			albumMoverClipboard.delegate?.didMoveAlbumsThenCommitDismiss()
		}
		
	}
	
}
