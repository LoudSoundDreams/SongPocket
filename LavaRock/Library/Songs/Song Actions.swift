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
			let selectedMediaItem = (viewModel.itemNonNil(at: selectedIndexPath) as? Song)?.mpMediaItem(),
			let player = player
		else { return }
		
		// TO DO: Mock `selectedMediaItem` in the Simulator.
		
		let selectedMediaItemAndBelow: [MPMediaItem]
		= viewModel
			.itemsInGroup(startingAt: selectedIndexPath)
			.compactMap { ($0 as? Song)?.mpMediaItem() }
		
		// Play now
		let playSongAndBelow = UIAlertAction(
			title: LocalizedString.playSongAndBelow,
			style: .default
		) { _ in
			player.playNow(selectedMediaItemAndBelow)
			deselectSelectedSong()
		}
		let playSong = UIAlertAction(
			title: LocalizedString.playSong,
			style: .default
		) { _ in
			player.playNow([selectedMediaItem])
			deselectSelectedSong()
		}
		// I want to silence VoiceOver after you choose “play now” actions, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.
		
		// Play next
		let prependSongAndBelow = UIAlertAction(
			title: LocalizedString.playSongAndBelowNext,
			style: .default
		) { _ in
			player.playNext(selectedMediaItemAndBelow)
			// TO DO: Show “Will Play Next” alert if not enabling Player screen
			deselectSelectedSong()
		}
		
		// Play last
		let firstSongTitle: String = {
			selectedMediaItem.titleOnDisk ?? SongMetadatumPlaceholder.unknownTitle
		}()
		let appendSongAndBelow = UIAlertAction(
			title: Enabling.songDotDotDot
			? LocalizedString.playSongAndBelowLater
			: LocalizedString.queueSongAndBelow,
			style: .default
		) { _ in
			player.playLast(selectedMediaItemAndBelow)
			self.alertWillPlayLaterIfShould(
				havingAppendedSongCount: selectedMediaItemAndBelow.count,
				firstSongTitle: firstSongTitle)
			deselectSelectedSong()
		}
		let appendSong = UIAlertAction(
			title: LocalizedString.queueSong,
			style: .default
		) { _ in
			player.playLast([selectedMediaItem])
			self.alertWillPlayLaterIfShould(
				havingAppendedSongCount: 1,
				firstSongTitle: firstSongTitle)
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
		if Enabling.songDotDotDot {
			actionSheet.addAction(playSongAndBelow)
		} else {
			if selectedMediaItemAndBelow.count == 1 {
				playSongAndBelow.isEnabled = false
				prependSongAndBelow.isEnabled = false
				appendSongAndBelow.isEnabled = false
			}
			actionSheet.addAction(playSongAndBelow)
			actionSheet.addAction(playSong)
			actionSheet.addAction(appendSongAndBelow)
			actionSheet.addAction(appendSong)
		}
		actionSheet.addAction(cancel)
		present(actionSheet, animated: true)
	}
	
	private func alertWillPlayLaterIfShould(
		havingAppendedSongCount songCount: Int,
		firstSongTitle: String
	) {
		let defaults = UserDefaults.standard
		let defaultsKey = LRUserDefaultsKey.shouldExplainQueueAction.rawValue
		
		defaults.register(defaults: [defaultsKey: true])
		guard
			!Enabling.console,
			defaults.bool(forKey: defaultsKey)
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
				if songCount == 1 {
					return String.localizedStringWithFormat(
						LocalizedString.format_didEnqueueOneSongAlertTitle,
						firstSongTitle)
				} else {
					return String.localizedStringWithFormat(
						LocalizedString.format_didEnqueueMultipleSongsAlertTitle,
						firstSongTitle, songCount - 1)
				}
			}(),
			message: LocalizedString.didEnqueueSongsAlertMessage,
			preferredStyle: .alert)
		alert.addAction(dontShowAgainAction)
		alert.addAction(okAction)
		alert.preferredAction = okAction
		willPlayLaterAlertIsPresented = true
		present(alert, animated: true)
	}
}
