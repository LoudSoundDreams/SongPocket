//
//  AlbumsTVC - “Move Albums” Sheet.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import Foundation

extension AlbumsTVC {
	func moveHere() {
		guard
			case let .movingAlbums(clipboard) = purpose,
			let albumsViewModel = viewModel as? AlbumsViewModel
		else { return }
		
		let newViewModel = albumsViewModel.updatedAfterInserting(
			albumsWith: clipboard.idsOfAlbumsBeingMoved)
		Task {
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else { return }
			
			viewModel.context.tryToSave()
			viewModel.context.parent!.tryToSave() // Save the main context now, even though we haven’t exited editing mode, because if you moved all the albums out of a collection, we’ll close the collection and exit editing mode shortly.
			
			NotificationCenter.default.post(name: .LRUserUpdatedDatabase, object: nil)
			MusicLibrary.shared.signal_userUpdatedDatabase.toggle()
		}
	}
}
