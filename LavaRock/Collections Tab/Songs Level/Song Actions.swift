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
		
		var allMediaItems = [MPMediaItem]()
		for songToEnqueue in indexedLibraryItems {
			guard let mediaItem = (songToEnqueue as? Song)?.mpMediaItem() else { continue }
			allMediaItems.append(mediaItem)
		}
		
		let mediaItemCollection = MPMediaItemCollection(items: allMediaItems)
		let queueDescriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: mediaItemCollection)
		queueDescriptor.startItem = allMediaItems[indexOfSelectedSong]
		
		playerController?.setQueue(with: queueDescriptor)
		playerController?.prepareToPlay()
		playerController?.play()
	}
	
	func enqueueAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		didDismissSongActions()
		let indexOfSelectedSong = selectedIndexPath.row - numberOfRowsAboveIndexedLibraryItems
		
		var mediaItemsToEnqueue = [MPMediaItem]()
		for indexOfSongToEnqueue in indexOfSelectedSong ... indexedLibraryItems.count - 1 {
			guard
				let songToEnqueue = indexedLibraryItems[indexOfSongToEnqueue] as? Song,
				let mediaItemToEnqueue = songToEnqueue.mpMediaItem()
			else { continue }
			mediaItemsToEnqueue.append(mediaItemToEnqueue)
		}
		
		let mediaItemCollection = MPMediaItemCollection(items: mediaItemsToEnqueue)
		let queueDescriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: mediaItemCollection)
		
		playerController?.append(queueDescriptor)
		if playerController?.playbackState != .playing {
			playerController?.prepareToPlay()
		}
	}
	
	func enqueueSelectedSong(_ sender: UIAlertAction) {
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		didDismissSongActions()
		let indexOfSong = selectedIndexPath.row - numberOfRowsAboveIndexedLibraryItems
		
		guard
			let song = indexedLibraryItems[indexOfSong] as? Song,
			let mediaItem = song.mpMediaItem()
		else { return }
		
		let mediaItemCollection = MPMediaItemCollection(items: [mediaItem])
		let queueDescriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: mediaItemCollection)
		
		playerController?.append(queueDescriptor)
		if playerController?.playbackState != .playing {
			playerController?.prepareToPlay()
		}
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
