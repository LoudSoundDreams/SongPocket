//
//  LibraryTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-08-29.
//

import UIKit
import SwiftUI

extension LibraryTVC: PlayerReflecting {
	func reflectPlaybackState() {
		reflectPlayer()
	}
}
extension LibraryTVC: PlaybackToolbarManaging {}
extension LibraryTVC {
	// MARK: - Database
	
	final func reflectDatabase() {
		reflectPlayer() // Do this even for views that aren’t visible, so that when we reveal them by going back, the “now playing” indicators and playback toolbar are already updated.
		
		if view.window == nil {
			needsFreshenLibraryItemsOnViewDidAppear = true
		} else {
			freshenLibraryItems()
		}
	}
	
	// MARK: Player
	
	// Subclasses that show a “now playing” indicator should override this method, call super (this implementation), and update that indicator.
	@objc
	func reflectPlayer() {
		// We want every `LibraryTVC` to have its playback toolbar freshened before it appears. This tells all `LibraryTVC`s to freshen, even if they aren’t onscreen. This works; it’s just unusual.
		freshenPlaybackToolbar()
	}
	
	// `LibraryTVC` itself doesn’t call this, but its subclasses might want to.
	final func indicateNowPlayingOnVisibleCells(
		accordingTo determining: NowPlayingDetermining
	) {
		tableView.indexPathsForVisibleRowsNonNil.forEach { visibleIndexPath in
			guard var cell = tableView.cellForRow(at: visibleIndexPath) as? NowPlayingIndicating else { return }
			cell.indicateNowPlaying(
				isInPlayer: determining.isInPlayer(anyIndexPath: visibleIndexPath),
				isPlaying: player?.playbackState == .playing)
		}
	}
	
	// MARK: Library Items
	
	@objc
	func shouldDismissAllViewControllersBeforeFreshenLibraryItems() -> Bool {
		return true
	}
	
	@objc
	func freshenLibraryItems() {
		isMergingChanges = false
		
		Task {
			/*
			 When we need to freshen, you might be in the middle of a content-dependent task. For simplicity, cancel such tasks.
			 - Sort options (`LibraryTVC`)
			 - “Rename Collection” dialog (`CollectionsTVC`)
			 - “Combine Collections” dialog (`CollectionsTVC`)
			 - “Organize or move albums?” menu (`AlbumsTVC`)
			 - “Organize albums” sheet (`CollectionsTVC` and `AlbumsTVC` when in “organize albums” sheet)
			 - “Move albums” sheet (`CollectionsTVC` and `AlbumsTVC` when in “move albums” sheet)
			 - “New Collection” dialog (`CollectionsTVC` when in “move albums” sheet)
			 - Song actions (`SongsTVC`)
			 - (Editing mode is a special state, but freshening in editing mode is fine (with no other “breath-holding modes” presented).)
			 */
			if shouldDismissAllViewControllersBeforeFreshenLibraryItems() {
				await view.window?.rootViewController?.dismiss__async(animated: true)
			}
			
			let newViewModel = viewModel.updatedWithFreshenedData()
			guard await setViewModelAndMoveRowsAndShouldContinue(newViewModel) else { return }
			
			freshenNavigationItemTitle()
			// Update the data within each row (and header), which might be outdated.
			// Doing it without an animation looks fine, because we animated the deletes, inserts, and moves earlier; here, we just change the contents of the rows after they stop moving.
			tableView.reconfigureRows(at: tableView.indexPathsForVisibleRowsNonNil)
		}
	}
}
