//
//  Song Actions.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit

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
			let player = TapeDeck.shared.player
		else { return }
		
		let selectedMediaItemAndBelow = mediaItems(startingAt: selectedIndexPath)
		
		let actionSheet = UIAlertController(
			title: nil,
			message: nil,
			preferredStyle: .actionSheet)
		actionSheet.popoverPresentationController?.sourceView = popoverAnchorView
		
		// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		let playToBottom = UIAlertAction(
			title: LRString.startPlaying,
			style: .default
		) { _ in
			player.playNow(selectedMediaItemAndBelow)
			
			deselectSelectedSong()
		}
//		playToBottom.isEnabled = selectedMediaItemAndBelow.count >= 2
		actionSheet.addAction(playToBottom)
		
		actionSheet.addAction(
			UIAlertAction.cancelWithHandler { _ in
				deselectSelectedSong()
			}
		)
		
		present(actionSheet, animated: true)
	}
}
