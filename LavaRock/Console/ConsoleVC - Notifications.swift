//
//  ConsoleVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2022-03-27.
//

import Foundation

extension ConsoleVC: TapeDeckReflecting {
	final func reflectPlaybackState() {
		reflectPlayhead()
	}
	
	final func reflectNowPlayingItem() {
		reflectPlayhead()
	}
}
extension ConsoleVC {
	// MARK: - Player
	
	@objc
	final func reflectPlayhead() {
		reelTable.indexPathsForVisibleRowsNonNil.forEach { visibleIndexPath in
			guard let cell = reelTable.cellForRow(
				at: visibleIndexPath) as? PlayheadReflectable
			else { return }
			cell.reflectPlayhead(
				containsPlayhead: Self.rowContainsPlayhead(at: visibleIndexPath))
		}
	}
}
