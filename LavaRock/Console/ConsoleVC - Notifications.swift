//
//  ConsoleVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2022-03-27.
//

import Foundation

extension ConsoleVC: TapeDeckReflecting {
	func reflectPlaybackState() {
		reflectPlayhead()
	}
}
extension ConsoleVC {
	// MARK: - Player
	
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
