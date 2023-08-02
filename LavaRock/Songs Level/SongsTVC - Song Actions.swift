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
		
		let mediaItemsInSection = mediaItems(startingAt: IndexPath(row: 2, section: 0)) // !
		
		let actionSheet = UIAlertController(
			title: nil,
			message: nil,
			preferredStyle: .actionSheet)
		actionSheet.popoverPresentationController?.sourceView = popoverAnchorView
		
		// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		let startPlaying = UIAlertAction(
			title: LRString.startPlaying,
			style: .default
		) { _ in
			let numberToSkip = selectedIndexPath.row - 2 // !
			player.playNow(mediaItemsInSection, skipping: numberToSkip)
			
			deselectSelectedSong()
		}
		actionSheet.addAction(startPlaying)
		
		actionSheet.addAction(
			UIAlertAction(title: LRString.cancel, style: .cancel) { _ in
				deselectSelectedSong()
			}
		)
		
		present(actionSheet, animated: true)
	}
}
