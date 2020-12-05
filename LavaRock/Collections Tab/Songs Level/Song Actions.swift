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
	
	// MARK: - Presenting Actions
	
	final func showSongActions(for song: Song) {
		areSongActionsPresented = true
		// You must set areSongActionsPresented = false when the action sheet is dismissed. Use this function for convenience.
		func didDismissSongActions() {
			areSongActionsPresented = false
		}
		
		// The row for the selected Song stays selected until we complete or cancel an action for it. So remember to deselect it in every possible branch from here. Use this function for convenience.
		func deselectSelectedSong() {
			tableView.deselectAllRows(animated: true)
		}
		
		// Create the actions.
		let playAlbumStartingHereAction = UIAlertAction(
			title: "Play Album Starting Here",
			style: .default,
			handler: { _ in
				didDismissSongActions()
				self.playAlbumStartingAtSelectedSong()
				deselectSelectedSong()
			}
		)
//		playAlbumStartingHereAction.accessibilityTraits = .startsMediaSession // I want to silence VoiceOver after you choose this action, but this line of code doesn't do it.
		let enqueueAlbumStartingHereAction = UIAlertAction(
			title: "Queue Album Starting Here",
			style: .default,
			handler: { _ in
				didDismissSongActions()
				self.enqueueAlbumStartingAtSelectedSong()
				deselectSelectedSong()
			}
		)
		let enqueueSongAction = UIAlertAction(
			title: "Queue Song",
			style: .default,
			handler: { _ in
				didDismissSongActions()
				self.enqueueSelectedSong()
				deselectSelectedSong()
			}
		)
		let cancelAction = UIAlertAction(
			title: "Cancel",
			style: .cancel,
			handler: { _ in
				didDismissSongActions()
				deselectSelectedSong()
			}
		)
		
		// Disable the actions that we shouldn't offer for the last Song in the section.
		if song == indexedLibraryItems.last {
			enqueueAlbumStartingHereAction.isEnabled = false
		}
		
		// Create and present the action sheet.
		let actionSheet = UIAlertController(
			title: nil,
			message: nil,
			preferredStyle: .actionSheet)
		actionSheet.addAction(playAlbumStartingHereAction)
		actionSheet.addAction(enqueueAlbumStartingHereAction)
		actionSheet.addAction(enqueueSongAction)
		actionSheet.addAction(cancelAction)
		present(actionSheet, animated: true, completion: nil)
	}
	
	// MARK: - Actions
	
	// MARK: Play
	
	private func playAlbumStartingAtSelectedSong() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		
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
	
	// MARK: Enqueue
	
	private func enqueueAlbumStartingAtSelectedSong() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		
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
		
		// Show explanation if the user is using this button for the first time
		
		guard let selectedSong = indexedLibraryItems[indexOfSelectedSong] as? Song else { return }
		
		let titleOfSelectedSong = selectedSong.titleFormattedOrPlaceholder()
		showExplanationIfNecessaryForEnqueueAction(
//			userDefaultsKeyForShouldShowExplanation: "shouldExplainQueueAlbumStartingHere",
			titleOfSelectedSong: titleOfSelectedSong,
			numberOfSongsEnqueued: mediaItemsToEnqueue.count)//,
//			didCompleteInteraction: deselectSelectedSong)
	}
	
	private func enqueueSelectedSong() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		
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
		
		// Show explanation if the user is using this button for the first time
		showExplanationIfNecessaryForEnqueueAction(
//			userDefaultsKeyForShouldShowExplanation: "shouldExplainQueueSong",
			titleOfSelectedSong: song.titleFormattedOrPlaceholder(),
			numberOfSongsEnqueued: 1)//,
//			didCompleteInteraction: deselectSelectedSong)
	}
	
	// MARK: Explaining Enqueue Actions
	
	private func showExplanationIfNecessaryForEnqueueAction(
//		userDefaultsKeyForShouldShowExplanation: String,
		titleOfSelectedSong: String,
		numberOfSongsEnqueued: Int//,
//		didCompleteInteraction: @escaping (() -> ())
	) {
		
		
//		UserDefaults.standard.removeObject(forKey: userDefaultsKeyForShouldShowExplanation) //
		
		
//		let shouldShowExplanation = UserDefaults.standard.value(forKey: userDefaultsKeyForShouldShowExplanation) as? Bool ?? true
//
//		guard shouldShowExplanation else {
//			didCompleteInteraction()
//			return
//		}
		
		let alertTitle: String
		switch numberOfSongsEnqueued {
		// The iOS HIG says to use sentence case and ending punctuation for alert titles that are complete sentences (e.g., "“Song Title” and 1 more song will play later."), but Apple's own apps usually don't do this.
		case 1:
			alertTitle  = "“\(titleOfSelectedSong)” Will Play Later"
		case 2:
			alertTitle = "“\(titleOfSelectedSong)” and 1 More Song Will Play Later"
		default:
			alertTitle = "“\(titleOfSelectedSong)” and \(numberOfSongsEnqueued - 1) More Songs Will Play Later"
		}
		let alertMessage = "You can edit the queue in the built-in Music app."
		
		let alert = UIAlertController(
			title: alertTitle,
			message: alertMessage,
			preferredStyle: .alert)
//		alert.addAction(
//			UIAlertAction(
//				title: "Don’t Show Again",
//				style: .default,
//				handler: { _ in
//					UserDefaults.standard.setValue(false, forKey: )
//					didCompleteInteraction()
//				} ))
		alert.addAction(
			UIAlertAction(
				title: "OK",
				style: .default,
				handler: nil))
//				handler: { _ in
////					UserDefaults.standard.setValue(false, forKey: )
//					didCompleteInteraction()
//				} ))
		present(alert, animated: true, completion: nil)
	}
	
}
