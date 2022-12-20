//
//  ConsoleVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2022-03-27.
//

import Foundation

extension ConsoleVC: TapeDeckReflecting {
	func reflect_playback_mode() {
		reflectPlayhead_console()
	}
	
	func reflect_now_playing_item() {
		reflectPlayhead_console()
	}
}
extension ConsoleVC {
	// MARK: - Player
	
	func reflectPlayhead_console() {
		reelTable.allIndexPaths().forEach { indexPath in
			guard let cell = reelTable.cellForRow(at: indexPath) as? PlayheadReflectable else { return }
			cell.reflectPlayhead(
				containsPlayhead: Self.rowContainsPlayhead(at: indexPath),
				rowContentAccessibilityLabel: cell.rowContentAccessibilityLabel)
		}
	}
}
