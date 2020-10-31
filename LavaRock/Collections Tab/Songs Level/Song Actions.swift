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
	
	final func playAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
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
		
		playerController?.setQueue(with: queueDescriptor)
		playerController?.repeatMode = .none
		playerController?.shuffleMode = .off
		playerController?.prepareToPlay()
		playerController?.play()
	}
	
	final func enqueueAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
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
		playerController?.repeatMode = .none
		playerController?.shuffleMode = .off
		if playerController?.playbackState != .playing {
			playerController?.prepareToPlay()
		}
	}
	
	final func enqueueSelectedSong(_ sender: UIAlertAction) {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
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
		playerController?.repeatMode = .none
		playerController?.shuffleMode = .off
		if playerController?.playbackState != .playing {
			playerController?.prepareToPlay()
		}
	}
	
	// MARK: - Presenting Actions
	
	final func showSongActions(for song: Song) {
		areSongActionsPresented = true
		
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		let playAlbumStartingHereAction = UIAlertAction(
			title: "Play Album Starting Here",
//			title: "Play Album Starting Here",
//			title: "Play Starting Here",
			style: .default,
			handler: playAlbumStartingAtSelectedSong)
//		playAlbumStartingHereAction.accessibilityTraits = .startsMediaSession // I want to silence VoiceOver after you choose this action, but this line of code doesn't do it.
		let enqueueAlbumStartingHereAction = UIAlertAction(
			title: "Queue Album Starting Here",
//			title: "Play Album Starting Here Later",
//			title: "Add to Queue Starting Here",
			style: .default,
			handler: enqueueAlbumStartingAtSelectedSong)
		let enqueueSongAction = UIAlertAction(
			title: "Queue Song",
//			title: "Play Song Later",
//			title: "Add to Queue",
			style: .default,
			handler: enqueueSelectedSong)
		
		// Disable the actions that we shouldn't offer for the last Song in the section.
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
