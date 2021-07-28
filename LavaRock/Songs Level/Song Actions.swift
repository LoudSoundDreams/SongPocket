//
//  Song Actions.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit
import CoreData
import MediaPlayer
import OSLog

extension SongsTVC {
	
	static let log = OSLog(
		subsystem: "LavaRock.Song",
		category: .pointsOfInterest)
	
	// MARK: - Presenting Actions
	
	final func showSongActions(
		for song: Song,
		popoverAnchorView: UIView
	) {
		// Keep the row for the selected Song selected until we complete or cancel an action for it. That means we also need to deselect it in every possible branch from here. Use this function for convenience.
		func deselectSelectedSong() {
			tableView.deselectAllRows(animated: true)
		}
		
		// Create the actions.
		let playAllStartingHereAction = UIAlertAction(
			title: LocalizedString.playAllStartingHere,
			style: .default,
			handler: { _ in
				self.playAllStartingAtSelectedSong()
				deselectSelectedSong()
			}
		)
//		playAllStartingHereAction.accessibilityTraits = .startsMediaSession // I want to silence VoiceOver after you choose this action, but this line of code doesn't do it.
		let enqueueAlbumStartingHereAction = UIAlertAction(
			title: LocalizedString.queueAlbumStartingHere,
			style: .default,
			handler: { _ in
				self.enqueueAlbumStartingAtSelectedSong()
				deselectSelectedSong()
			}
		)
		let enqueueSongAction = UIAlertAction(
			title: LocalizedString.queueSong,
			style: .default,
			handler: { _ in
				self.enqueueSelectedSong()
				deselectSelectedSong()
			}
		)
		let cancelAction = UIAlertAction.cancel { _ in
			deselectSelectedSong()
		}
		
		// Disable the actions that we shouldn't offer for the last Song in the section.
		if song == sectionOfLibraryItems.items.last {
			enqueueAlbumStartingHereAction.isEnabled = false
		}
		
		// Create and present the action sheet.
		let actionSheet = UIAlertController(
			title: nil,
			message: nil,
			preferredStyle: .actionSheet)
		actionSheet.addAction(playAllStartingHereAction)
		actionSheet.addAction(enqueueAlbumStartingHereAction)
		actionSheet.addAction(enqueueSongAction)
		actionSheet.addAction(cancelAction)
		actionSheet.popoverPresentationController?.sourceView = popoverAnchorView
		present(actionSheet, animated: true)
	}
	
	// MARK: - Actions
	
	// MARK: Play
	
	private func playAllStartingAtSelectedSong() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		
		let indexOfSelectedSong = indexOfLibraryItem(for: selectedIndexPath)
		let chosenSongs = sectionOfLibraryItems.items[indexOfSelectedSong...]
		os_signpost(
			.begin,
			log: Self.log,
			name: "Get chosen MPMediaItems")
		let chosenMediaItems = chosenSongs.compactMap {
			($0 as? Song)?.mpMediaItem()
		}
//		let chosenMediaItems: [MPMediaItem] = {
//			guard let sectionOfSongs = sectionOfLibraryItems as? SectionOfSongs else {
//				return chosenSongs.compactMap {
//					($0 as? Song)?.mpMediaItem()
//				}
//			}
//			return sectionOfSongs.mpMediaItemsCompactFast(for: Array(chosenSongs))
//		}()
		os_signpost(
			.end,
			log: Self.log,
			name: "Get chosen MPMediaItems")
		let mediaItemCollection = MPMediaItemCollection(items: chosenMediaItems)
		let queueDescriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: mediaItemCollection)
		
		sharedPlayer?.setQueue(with: queueDescriptor)
		
		// As of iOS 14.7 beta 1, you must set repeatMode and shuffleMode after calling setQueue, or else the repeat mode and shuffle mode won't actually apply.
		sharedPlayer?.repeatMode = .none
		sharedPlayer?.shuffleMode = .off
		
		sharedPlayer?.play() // Calls prepareToPlay auomatically
	}
	
	// MARK: Enqueue
	
	private func enqueueAlbumStartingAtSelectedSong() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		
		let indexOfSelectedSong = indexOfLibraryItem(for: selectedIndexPath)
		let chosenSongs = sectionOfLibraryItems.items[indexOfSelectedSong...]
		os_signpost(
			.begin,
			log: Self.log,
			name: "Get chosen MPMediaItems")
		let chosenMediaItems = chosenSongs.compactMap {
			($0 as? Song)?.mpMediaItem()
		}
//		let chosenMediaItems: [MPMediaItem] = {
//			guard let sectionOfSongs = sectionOfLibraryItems as? SectionOfSongs else {
//				return chosenSongs.compactMap {
//					($0 as? Song)?.mpMediaItem()
//				}
//			}
//			return sectionOfSongs.mpMediaItemsCompactFast(for: Array(chosenSongs))
//		}()
		os_signpost(
			.end,
			log: Self.log,
			name: "Get chosen MPMediaItems")
		let mediaItemCollection = MPMediaItemCollection(items: chosenMediaItems)
		let queueDescriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: mediaItemCollection)
		
		sharedPlayer?.append(queueDescriptor)
		
		sharedPlayer?.repeatMode = .none
		sharedPlayer?.shuffleMode = .off
		
		// As of iOS 14.7 beta 1, you must do this in case the user force quit the built-in Music app recently.
		if sharedPlayer?.playbackState != .playing {
			sharedPlayer?.prepareToPlay()
		}
		
		if
			let selectedSong = libraryItem(for: selectedIndexPath) as? Song,
			let selectedMediaItem = selectedSong.mpMediaItem()
		{
			let selectedTitle = selectedMediaItem.title ?? MPMediaItem.placeholderTitle
			showExplanationIfNecessaryForEnqueueAction(
				userDefaultsKeyForShouldShowExplanation: UserDefaults.LRKey.shouldExplainQueueAction,
				titleOfSelectedSong: selectedTitle,
				numberOfSongsEnqueued: chosenMediaItems.count)
		}
	}
	
	private func enqueueSelectedSong() {
		guard
			MPMediaLibrary.authorizationStatus() == .authorized,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		else { return }
		
		let indexOfSong = indexOfLibraryItem(for: selectedIndexPath)
		guard
			let selectedSong = sectionOfLibraryItems.items[indexOfSong] as? Song,
			let selectedMediaItem = selectedSong.mpMediaItem()
		else { return }
		let mediaItemCollection = MPMediaItemCollection(items: [selectedMediaItem])
		let queueDescriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: mediaItemCollection)
		
		sharedPlayer?.append(queueDescriptor)
		
		sharedPlayer?.repeatMode = .none
		sharedPlayer?.shuffleMode = .off
		
		// As of iOS 14.7 beta 1, you must do this in case the user force quit the built-in Music app recently.
		if sharedPlayer?.playbackState != .playing {
			sharedPlayer?.prepareToPlay()
		}
		
		let selectedTitle = selectedMediaItem.title ?? MPMediaItem.placeholderTitle
		showExplanationIfNecessaryForEnqueueAction(
			userDefaultsKeyForShouldShowExplanation: UserDefaults.LRKey.shouldExplainQueueAction,
			titleOfSelectedSong: selectedTitle,
			numberOfSongsEnqueued: 1)
	}
	
	// MARK: Explaining Enqueue Actions
	
	private func showExplanationIfNecessaryForEnqueueAction(
		userDefaultsKeyForShouldShowExplanation: UserDefaults.LRKey,
		titleOfSelectedSong: String,
		numberOfSongsEnqueued: Int
	) {
		let shouldShowExplanation = UserDefaults.standard.value(forKey: userDefaultsKeyForShouldShowExplanation.rawValue) as? Bool ?? true
		guard shouldShowExplanation else { return }
		
		let alertTitle: String
		switch numberOfSongsEnqueued {
		// The Human Interface Guidelines say to use sentence case and ending punctuation for alert titles that are complete sentences (e.g., "“Song Title” and 1 more song will play later."), but Apple's own apps usually don't do this.
		case 1:
			let formatString = LocalizedString.formatDidEnqueueOneSongAlertTitle
			alertTitle = String.localizedStringWithFormat(
				formatString,
				titleOfSelectedSong)
		default:
			let formatString = LocalizedString.formatDidEnqueueMultipleSongsAlertTitle
			alertTitle = String.localizedStringWithFormat(
				formatString,
				titleOfSelectedSong, numberOfSongsEnqueued - 1)
		}
		let alertMessage = LocalizedString.didEnqueueSongsAlertMessage
		
		let alert = UIAlertController(
			title: alertTitle,
			message: alertMessage,
			preferredStyle: .alert)
		let dontShowAgainAction = UIAlertAction(
			title: LocalizedString.dontShowAgain,
			style: .default,
			handler: { _ in
				UserDefaults.standard.set(
					false,
					forKey: userDefaultsKeyForShouldShowExplanation.rawValue)
			}
		)
		let okAction = UIAlertAction(
			title: LocalizedString.ok,
			style: .default,
			handler: nil)
		alert.addAction(dontShowAgainAction)
		alert.addAction(okAction)
		alert.preferredAction = okAction
		present(alert, animated: true)
	}
	
}
