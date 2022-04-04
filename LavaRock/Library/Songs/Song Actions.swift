//
//  Song Actions.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit
import MediaPlayer

extension SongsTVC {
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
		
		// Rest of album
		let selectedSongAndBelow: [Song] = viewModel
			.itemsInGroup(startingAt: selectedIndexPath)
			.compactMap { $0 as? Song }
		let playRestOfAlbum = UIAlertAction(
			title: LocalizedString.playRestOfAlbum,
			style: .default
		) { _ in
			player.playNow(selectedSongAndBelow)
			deselectSelectedSong()
		}
		// I want to silence VoiceOver after you choose “play now” actions, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.
		let appendRestOfAlbum = UIAlertAction(
			title: LocalizedString.queueRestOfAlbum,
			style: .default
		) { _ in
			player.playLast(selectedSongAndBelow)
			self.alertWillPlayLaterIfShould(havingAppended: selectedSongAndBelow)
			deselectSelectedSong()
		}
		if selectedSongAndBelow.count == 1 {
			playRestOfAlbum.isEnabled = false
			appendRestOfAlbum.isEnabled = false
		}
		
		// Single song
		let playSong = UIAlertAction(
			title: LocalizedString.play,
			style: .default
		) { _ in
			player.playNow([selectedSong])
			deselectSelectedSong()
		}
		let appendSong = UIAlertAction(
			title: LocalizedString.queue__verb,
			style: .default
		) { _ in
			player.playLast([selectedSong])
			self.alertWillPlayLaterIfShould(havingAppended: [selectedSong])
			deselectSelectedSong()
		}
		
		let cancel = UIAlertAction.cancel { _ in
			deselectSelectedSong()
		}
		
		let actionSheet = UIAlertController(
			title: nil,
			message: nil,
			preferredStyle: .actionSheet)
		actionSheet.popoverPresentationController?.sourceView = popoverAnchorView
		actionSheet.addAction(playRestOfAlbum)
		actionSheet.addAction(appendRestOfAlbum)
		actionSheet.addAction(playSong)
		actionSheet.addAction(appendSong)
		actionSheet.addAction(cancel)
		present(actionSheet, animated: true)
	}
	
	private func alertWillPlayLaterIfShould(
		havingAppended songs: [Song]
	) {
		let defaults = UserDefaults.standard
		let defaultsKey = LRUserDefaultsKey.shouldExplainQueueAction.rawValue
		
		defaults.register(defaults: [defaultsKey: true])
		guard
			!Enabling.playerScreen,
			defaults.bool(forKey: defaultsKey),
			let titleOfSelectedSong = songs.first?.metadatum()?.titleOnDisk
		else { return }
		
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
		
		let alert = UIAlertController(
			title: {
				switch songs.count {
				case 1:
					return String.localizedStringWithFormat(
						LocalizedString.format_didEnqueueOneSongAlertTitle,
						titleOfSelectedSong)
				default:
					return String.localizedStringWithFormat(
						LocalizedString.format_didEnqueueMultipleSongsAlertTitle,
						titleOfSelectedSong, songs.count - 1)
				}}(),
			message: LocalizedString.didEnqueueSongsAlertMessage,
			preferredStyle: .alert)
		alert.addAction(dontShowAgainAction)
		alert.addAction(okAction)
		alert.preferredAction = okAction
		willPlayLaterAlertIsPresented = true
		present(alert, animated: true)
	}
}
