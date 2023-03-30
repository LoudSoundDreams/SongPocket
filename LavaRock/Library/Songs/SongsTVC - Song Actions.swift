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
			let player = player
		else { return }
		
		let selectedMediaItemAndBelow = mediaItems(startingAt: selectedIndexPath)
		
		func playRestOfAlbumAndDeselect() {
			player.playNow(
				selectedMediaItemAndBelow,
				new_repeat_mode: .none,
				disable_shuffle: true)
			
			deselectSelectedSong()
		}
		
		// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		
		if player.playbackState == .playing {
			
			let actionSheet = UIAlertController(
				title: "Interrupt current song?", // TO DO
				message: nil,
				preferredStyle: .actionSheet)
			actionSheet.popoverPresentationController?.sourceView = popoverAnchorView
			
			let confirmPlay = UIAlertAction(
				title: "Continue", // TO DO
				style: .default
			) { alertAction in
				playRestOfAlbumAndDeselect()
			}
			actionSheet.addAction(confirmPlay)
			
			actionSheet.addAction(
				UIAlertAction.cancelWithHandler { _ in
					deselectSelectedSong()
				}
			)
			
			present(actionSheet, animated: true)
			
		} else {
			
			playRestOfAlbumAndDeselect()
			
		}
	}
}
