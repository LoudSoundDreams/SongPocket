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
		reflectPlayheadAndFreshenTransportBar_library()
	}
}
extension LibraryTVC {
	// MARK: - Database
	
	final func reflectDatabase() {
		// Do this even if the view isn’t visible.
		reflectPlayheadAndFreshenTransportBar_library()
		
		if view.window == nil {
			needsFreshenLibraryItemsOnViewDidAppear = true
		} else {
			freshenLibraryItems()
		}
	}
	
	// MARK: Player
	
	@objc
	func reflectPlayheadAndFreshenTransportBar_library() {
		// Freshen “now playing” indicators
		tableView.indexPathsForVisibleRowsNonNil.forEach { visibleIndexPath in
			guard
				let cell = tableView.cellForRow(at: visibleIndexPath) as? PlayheadReflectable,
				let libraryItem = viewModel.itemOptional(at: visibleIndexPath) as? LibraryItem
			else { return }
			cell.reflectPlayhead(containsPlayhead: libraryItem.containsPlayhead())
		}
		
		// Do this even if the view isn’t visible.
		(navigationController as? LibraryNC)?.transportBar.freshen()
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
