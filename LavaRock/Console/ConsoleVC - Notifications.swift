//
//  ConsoleVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2022-03-27.
//

import Foundation

extension ConsoleVC: PlayerReflecting {
	func reflectPlaybackState() {
		reflectPlayheadAndFreshenTransportToolbar_console()
	}
}
extension ConsoleVC: TransportToolbarManaging {}
extension ConsoleVC {
	// MARK: - Player
	
	final func reflectPlayheadAndFreshenTransportToolbar_console() {
		queueTable.indexPathsForVisibleRowsNonNil.forEach { visibleIndexPath in
			guard let cell = queueTable.cellForRow(
				at: visibleIndexPath) as? PlayheadReflectable
			else { return }
			cell.reflectPlayhead(
				containsPlayhead: Self.rowContainsPlayhead(at: visibleIndexPath))
		}
		
		freshenTransportToolbar()
	}
}
