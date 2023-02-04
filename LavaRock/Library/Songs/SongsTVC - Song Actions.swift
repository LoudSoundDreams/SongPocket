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
		
		let selectedMediaItemAndBelow = mediaItems(startingAt: selectedIndexPath)
		
		// Create action sheet
		let actionSheet = UIAlertController(
			title: nil,
			message: nil,
			preferredStyle: .actionSheet)
		actionSheet.popoverPresentationController?.sourceView = popoverAnchorView
		
		// Add actions
		
		// For actions that start playback:
		// I want to silence VoiceOver after you choose “play now” actions, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		
		// Play song and below now
		let playSongAndBelow = UIAlertAction(
			title: LRString.playRestOfAlbum,
			style: .default
		) { _ in
			player.playNow(
				selectedMediaItemAndBelow,
				new_repeat_mode: .none,
				disable_shuffle: true)
			
			deselectSelectedSong()
		}
		playSongAndBelow.isEnabled = selectedMediaItemAndBelow.count >= 2
		actionSheet.addAction(playSongAndBelow)
		
		// Play song now
		let playSong = UIAlertAction(
			title: LRString.playSong,
			style: .default
		) { _ in
			player.playNow(
				[selectedMediaItem],
				new_repeat_mode: .none,
				disable_shuffle: true)
			
			deselectSelectedSong()
		}
		actionSheet.addAction(playSong)
		
		// Cancel
		actionSheet.addAction(
			UIAlertAction.cancelWithHandler { _ in
				deselectSelectedSong()
			}
		)
		
		// —
		
		// Present
		present(actionSheet, animated: true)
	}
}
