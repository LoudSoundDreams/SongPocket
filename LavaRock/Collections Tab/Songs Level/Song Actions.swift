//
//  Song Actions.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit
import CoreData
import MediaPlayer

extension SongsTVC {
	
	// MARK: - Actions
	
	func playAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		didDismissSongActions()
		let indexOfSelectedSong = selectedIndexPath.row - numberOfRowsAboveIndexedLibraryItems
		var songIDsToEnqueue = [NSManagedObjectID]()
		for indexOfSongToEnqueue in indexOfSelectedSong ... indexedLibraryItems.count - 1 {
			let songToEnqueue = indexedLibraryItems[indexOfSongToEnqueue]
			songIDsToEnqueue.append(songToEnqueue.objectID)
		}
		
		QueueController.shared.setPlayerQueueWith(songsWithObjectIDs: songIDsToEnqueue)
		playerController.prepareToPlay()
		playerController.play()
	}
	
	func enqueueAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		didDismissSongActions()
		let indexOfSelectedSong = selectedIndexPath.row - numberOfRowsAboveIndexedLibraryItems
		var songIDsToEnqueue = [NSManagedObjectID]()
		for indexOfSongToEnqueue in indexOfSelectedSong ... indexedLibraryItems.count - 1 {
			let songToEnqueue = indexedLibraryItems[indexOfSongToEnqueue]
			songIDsToEnqueue.append(songToEnqueue.objectID)
		}
		
		QueueController.shared.appendToPlayerQueue(songsWithObjectIDs: songIDsToEnqueue)
		
		
	}
	
	func enqueueSelectedSong(_ sender: UIAlertAction) {
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		didDismissSongActions()
		let indexOfSong = selectedIndexPath.row - numberOfRowsAboveIndexedLibraryItems
		let song = indexedLibraryItems[indexOfSong]
		let songID = song.objectID
		
		QueueController.shared.appendToPlayerQueue(songWithObjectID: songID)
		
		
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
		let _ = QueueController.shared
	}
	
	// MARK: Dismissing Actions
	
	private func didDismissSongActions() {
		tableView.deselectAllRows(animated: true)
		areSongActionsPresented = false
	}
	
}
