//
//  AlbumsTVC - “Move Albums” Sheet.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	final func moveHere() {
		guard
			let albumsViewModel = viewModel as? AlbumsViewModel,
			case let .movingAlbums(clipboard) = purpose,
			!clipboard.didAlreadyCommitMove // Without this, if you tap the "Move Here" button more than once, the app crashes. You can tap that button more than once because it receives events during table view updates, which run asynchronously.
		else { return }
		
		clipboard.didAlreadyCommitMove = true
		
		let newViewModel = albumsViewModel.updatedAfterMovingIntoOnlyGroup(
			albumsWith: clipboard.idsOfAlbumsBeingMoved)
		setViewModelAndMoveRows(newViewModel) {
			self.viewModel.context.tryToSave()
			self.viewModel.context.parent!.tryToSave() // Save the main context now, even though we haven't exited editing mode, because if you moved all the `Album`s out of a `Collection`, we'll close the `Collection` and exit editing mode shortly.
			
			NotificationCenter.default.post(
				Notification(name: .LRUserDidUpdateDatabase)
			)
			
			self.dismiss(animated: true)
			clipboard.delegate?.didMoveThenDismiss()
		}
	}
	
}
