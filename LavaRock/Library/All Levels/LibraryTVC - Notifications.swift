//
//  LibraryTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-08-29.
//

import UIKit
import SwiftUI

extension Notification.Name {
	static let userUpdatedDatabase = Self("user updated database")
}

extension LibraryTVC: TapeDeckReflecting {
	final func reflectPlaybackState() {
		reflectPlayhead_library()
	}
	
	final func reflectNowPlayingItem() {
		reflectPlayhead_library()
	}
}
extension LibraryTVC {
	// MARK: Player
	
	final func reflectPlayhead_library() {
		tableView.indexPathsForVisibleRowsNonNil.forEach { visibleIndexPath in
			guard
				let cell = tableView.cellForRow(at: visibleIndexPath) as? PlayheadReflectable,
				let libraryItem = viewModel.itemOptional(at: visibleIndexPath) as? LibraryItem
			else { return }
			cell.reflectPlayhead(containsPlayhead: libraryItem.containsPlayhead())
		}
	}
}
