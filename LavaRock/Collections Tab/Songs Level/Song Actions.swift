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
		
		let actionSheet = UIAlertController(
			title: nil,
			message: nil,
			preferredStyle: .actionSheet)
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
				handler: { _ in
					self.deselectSelectedSong()
					self.didDismissSongActions()
				}
			)
		)
		present(actionSheet, animated: true, completion: nil)
	}
	
	// MARK: - Actions
	
	private func playAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		defer {
			deselectSelectedSong()
			didDismissSongActions()
		}
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
	
	private func enqueueAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		defer { didDismissSongActions() }
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else {
			deselectSelectedSong()
			return
		}
		
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
		
		guard let selectedSong = indexedLibraryItems[indexOfSelectedSong] as? Song else {
			deselectSelectedSong()
			return
		}
		
		let titleOfSelectedSong = selectedSong.titleFormattedOrPlaceholder()
		showExplanationIfNecessaryForEnqueueAction(
//			userDefaultsKeyForShouldShowExplanation: "shouldExplainQueueAlbumStartingHere",
			titleOfSelectedSong: titleOfSelectedSong,
			numberOfSongsEnqueued: mediaItemsToEnqueue.count,
			didCompleteInteraction: deselectSelectedSong)
	}
	
	private func enqueueSelectedSong(_ sender: UIAlertAction) {
		defer { didDismissSongActions() }
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else {
			deselectSelectedSong()
			return
		}
		
		let indexOfSong = selectedIndexPath.row - numberOfRowsAboveIndexedLibraryItems
		guard
			let song = indexedLibraryItems[indexOfSong] as? Song,
			let mediaItem = song.mpMediaItem()
		else {
			deselectSelectedSong()
			return
		}
		
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
			numberOfSongsEnqueued: 1,
			didCompleteInteraction: deselectSelectedSong)
	}
	
	// MARK: Showing Explanation for Enqueue Actions
	
	private func showExplanationIfNecessaryForEnqueueAction(
//		userDefaultsKeyForShouldShowExplanation: String,
		titleOfSelectedSong: String,
		numberOfSongsEnqueued: Int,
		didCompleteInteraction: @escaping (() -> ())
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
		// The iOS HIG says to use sentence case and ending punctuation for alert titles that are complete sentences (e.g., "Song Title and 1 more song will play later."), but Apple doesn't follow its own advice.
		case 1:
			alertTitle  = "“\(titleOfSelectedSong)” Will Play Later"
		case 2:
			alertTitle = "“\(titleOfSelectedSong)” and 1 More Song Will Play Later"
		default:
			alertTitle = "“\(titleOfSelectedSong)” and \(numberOfSongsEnqueued - 1) More Songs Will Play Later"
		}
		let alertMessage = "You can view and edit the queue in the Apple Music app."
		
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
				handler: { _ in
//					UserDefaults.standard.setValue(false, forKey: )
					didCompleteInteraction()
				} ))
		present(alert, animated: true, completion: nil)
	}
	
	// MARK: - Dismissing Actions
	
	private func didDismissSongActions() {
		areSongActionsPresented = false
	}
	
	private func deselectSelectedSong() {
		tableView.deselectAllRows(animated: true)
	}
	
}
