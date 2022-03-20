//
//  Song Actions.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit
import MediaPlayer
import OSLog

extension SongsTVC {
	// MARK: Presenting
	
	final func showSongActions(
		for song: Song,
		popoverAnchorView: UIView
	) {
		// Keep the row for the selected `Song` selected until we complete or cancel an action for it. That means we also need to deselect it in every possible branch from here. Use this function for convenience.
		func deselectSelectedSong() {
			tableView.deselectAllRows(animated: true)
		}
		
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow,
			let selectedSong = viewModel.itemNonNil(at: selectedIndexPath) as? Song,
			let player = player
		else { return }
		
		let selectedSongAndBelow: [Song] = viewModel
			.itemsInGroup(startingAt: selectedIndexPath)
			.compactMap { $0 as? Song }
		let playRestOfAlbum = UIAlertAction(
			title: LocalizedString.playRestOfAlbum,
			style: .default
		) { _ in
			player.play(selectedSongAndBelow)
			deselectSelectedSong()
		}
		// I want to silence VoiceOver after you choose “play now” actions, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.
		let appendRestOfAlbum = UIAlertAction(
			title: LocalizedString.queueRestOfAlbum,
			style: .default
		) { _ in
			self.append(selectedSongAndBelow, using: player)
			deselectSelectedSong()
		}
		if selectedSongAndBelow.count == 1 {
			playRestOfAlbum.isEnabled = false
			appendRestOfAlbum.isEnabled = false
		}
		
		let playSong = UIAlertAction(
			title: "Play Song", // L2DO
			style: .default
		) { _ in
			player.play([selectedSong])
			deselectSelectedSong()
		}
		let appendSong = UIAlertAction(
			title: LocalizedString.queueSong,
			style: .default
		) { _ in
			self.append([selectedSong], using: player)
			deselectSelectedSong()
		}
		
		let cancel = UIAlertAction.cancel { _ in
			deselectSelectedSong()
		}
		
		let actionSheet = UIAlertController(
			title: nil,
			message: nil,
			preferredStyle: .actionSheet)
		
		if Enabling.wholeAlbumButtons {
			actionSheet.addAction(playRestOfAlbum)
			actionSheet.addAction(appendRestOfAlbum)
			actionSheet.addAction(playSong)
			actionSheet.addAction(appendSong)
		} else {
			actionSheet.addAction(playRestOfAlbum)
			actionSheet.addAction(appendRestOfAlbum)
			actionSheet.addAction(appendSong)
		}
		actionSheet.addAction(cancel)
		
		actionSheet.popoverPresentationController?.sourceView = popoverAnchorView
		
		present(actionSheet, animated: true)
	}
	
	// MARK: Actions
	
	private func append(
		_ songs: [Song],
		using player: MPMusicPlayerController
	) {
		if Enabling.playerScreen {
			SongQueue.contents.append(contentsOf: songs)
		}
		player.append(
			MPMusicPlayerMediaItemQueueDescriptor(
				itemCollection: MPMediaItemCollection(
					items: songs.compactMap { $0.mpMediaItem() })))
		
		player.repeatMode = .none
		
		// As of iOS 14.7 developer beta 1, you must do this in case the user force quit the built-in Music app recently.
		if player.playbackState != .playing {
			player.prepareToPlay()
		}
		
		if Enabling.playerScreen {
		} else {
			if
				let selectedSong = songs.first,
				let selectedMetadata = selectedSong.metadatum()
			{
				let selectedTitle = selectedMetadata.titleOnDisk ?? SongMetadatumExtras.unknownTitlePlaceholder
				presentWillPlayLaterAlertIfShould(
					titleOfSelectedSong: selectedTitle,
					numberOfSongsEnqueued: songs.count)
			}
		}
	}
	
	// MARK: “Will Play Later” Alert
	
	private func presentWillPlayLaterAlertIfShould(
		titleOfSelectedSong: String,
		numberOfSongsEnqueued: Int
	) {
		let defaults = UserDefaults.standard
		let defaultsKey = LRUserDefaultsKey.shouldExplainQueueAction.rawValue
		
		defaults.register(defaults: [defaultsKey: true])
		let shouldShowExplanation = defaults.bool(forKey: defaultsKey)
		guard shouldShowExplanation else { return }
		
		let alertTitle: String
		switch numberOfSongsEnqueued {
		case 1:
			alertTitle = String.localizedStringWithFormat(
				LocalizedString.format_didEnqueueOneSongAlertTitle,
				titleOfSelectedSong)
		default:
			alertTitle = String.localizedStringWithFormat(
				LocalizedString.format_didEnqueueMultipleSongsAlertTitle,
				titleOfSelectedSong, numberOfSongsEnqueued - 1)
		}
		let alertMessage = LocalizedString.didEnqueueSongsAlertMessage
		
		let alert = UIAlertController(
			title: alertTitle,
			message: alertMessage,
			preferredStyle: .alert)
		let dontShowAgainAction = UIAlertAction(
			title: LocalizedString.dontShowAgain,
			style: .default
		) { _ in
			self.willPlayLaterAlertIsPresented = false
			defaults.set(
				false,
				forKey: defaultsKey)
		}
		let okAction = UIAlertAction(
			title: LocalizedString.ok,
			style: .default
		) { _ in
			self.willPlayLaterAlertIsPresented = false
		}
		
		alert.addAction(dontShowAgainAction)
		alert.addAction(okAction)
		alert.preferredAction = okAction
		
		willPlayLaterAlertIsPresented = true
		present(alert, animated: true)
	}
}
