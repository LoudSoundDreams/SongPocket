//
//  Song Actions.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit
import CoreData

//extension Notification.Name {
//	static let LREnqueueSongs = Notification.Name("The user just told us to add some songs to the end of the queue. This notification’s `object` is an array of NSManagedObjectIDs for some Songs; enqueue the MPMediaItems associated with them.")
//}

extension SongsTVC {
	
	// MARK: - Actions
	
	func playAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		didDismissSongActions()
		let indexOfSelectedSong = selectedIndexPath.row - numberOfRowsAboveIndexedLibraryItems
		var objectIDsOfSongsToEnqueue = [NSManagedObjectID]()
		for indexOfSongToEnqueue in indexOfSelectedSong ... indexedLibraryItems.count - 1 {
			let songToEnqueue = indexedLibraryItems[indexOfSongToEnqueue]
			objectIDsOfSongsToEnqueue.append(songToEnqueue.objectID)
		}
		
		
//		NotificationCenter.default.post(
//			name: Notification.Name.LREnqueueSongs,
//			object: objectIDsOfSongsToEnqueue)
	}
	
	func enqueueAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		
		
		didDismissSongActions()
	}
	
	func enqueueSelectedSong(_ sender: UIAlertAction) {
		
		
		didDismissSongActions()
	}
	
	// MARK: - Presenting Actions
	
	func showSongActions(for song: Song) {
		areSongActionsPresented = true
		
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		let playAlbumStartingHereAction = UIAlertAction(
			title: "Play Starting Here",
			style: .destructive,
			handler: playAlbumStartingAtSelectedSong
		)
		let enqueueSongAction = UIAlertAction(
			title: "Add to Queue",
			style: .default,
			handler: enqueueSelectedSong
		)
		let enqueueAlbumStartingHereAction = UIAlertAction(
			title: "Add to Queue Starting Here",
			style: .default,
			handler: enqueueAlbumStartingAtSelectedSong
		)
		
		// Disable the actions that we shouldn't offer for the last song in the section.
		if song == indexedLibraryItems.last {
			enqueueAlbumStartingHereAction.isEnabled = false
		}
		
		actionSheet.addAction(playAlbumStartingHereAction)
		actionSheet.addAction(enqueueAlbumStartingHereAction)
		actionSheet.addAction(enqueueSongAction)
		actionSheet.addAction(
			UIAlertAction(
				title: "Cancel",
				style: .cancel,
				handler: { _ in self.didDismissSongActions() }
			)
		)
		present(actionSheet, animated: true, completion: nil)
	}
	
	// MARK: Dismissing Actions
	
	private func didDismissSongActions() {
		tableView.deselectAllRows(animated: true)
		areSongActionsPresented = false
	}
	
}
