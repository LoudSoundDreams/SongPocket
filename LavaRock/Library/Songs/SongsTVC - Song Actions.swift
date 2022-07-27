//
//  Song Actions.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit
import MediaPlayer

extension SongsTVC {
	func showSongActions(
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
		let firstSongTitle: String = {
			selectedMediaItem.titleOnDisk ?? SongMetadatumPlaceholder.unknownTitle
		}()
		
		// Create action sheet
		
		let actionSheet = UIAlertController(
			title: String.localizedStringWithFormat(
				LRString.format_xSongs,
				selectedMediaItemAndBelow.count),
			message: nil,
			preferredStyle: .actionSheet)
		actionSheet.popoverPresentationController?.sourceView = popoverAnchorView
		
		// Add actions
		
		// Play
		actionSheet.addAction(
			UIAlertAction(
				title: LRString.play,
				style: .default
			) { _ in
				player.playNow(
					selectedMediaItemAndBelow,
					new_repeat_mode: .none,
					disable_shuffle: true)
				deselectSelectedSong()
			}
			// I want to silence VoiceOver after you choose “play now” actions, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		)
		
		// Play next
		let playNextAction = UIAlertAction(
			title: LRString.queueNext,
			style: .default
		) { _ in
			player.playNext(selectedMediaItemAndBelow)
			self.presentOpenMusicAlertIfNeeded(
				willPlayNextAsOpposedToLast: true,
				havingVerbedSongCount: selectedMediaItemAndBelow.count,
				firstSongTitle: firstSongTitle)
			deselectSelectedSong()
		}
		actionSheet.addAction(playNextAction)
		
		// Play last
		let playLastAction = UIAlertAction(
			title: LRString.queueLast,
			style: .default
		) { _ in
			player.playLast(selectedMediaItemAndBelow)
			self.presentOpenMusicAlertIfNeeded(
				willPlayNextAsOpposedToLast: false,
				havingVerbedSongCount: selectedMediaItemAndBelow.count,
				firstSongTitle: firstSongTitle)
			deselectSelectedSong()
		}
		// Disable if appropriate
		playLastAction.isEnabled = Reel.shouldEnablePlayLast()
		actionSheet.addAction(playLastAction)
		
		// Cancel
		actionSheet.addAction(
			UIAlertAction.cancelWithHandler { _ in
				deselectSelectedSong()
			}
		)
		
		// Present
		
		present(actionSheet, animated: true)
	}
}
