//
//  ConsoleVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2022-03-27.
//

import Foundation

extension ConsoleVC: PlayerReflecting {
	func playbackStateDidChange() {
		freshenNowPlayingIndicatorsAndTransportToolbar_console()
	}
}
extension ConsoleVC: TransportToolbarManaging {}
extension ConsoleVC {
	// MARK: - Player
	
	final func freshenNowPlayingIndicatorsAndTransportToolbar_console() {
		queueTable.indexPathsForVisibleRowsNonNil.forEach { visibleIndexPath in
			guard let cell = queueTable.cellForRow(
				at: visibleIndexPath) as? NowPlayingIndicating
			else { return }
			cell.indicateNowPlaying(
				isInPlayer: Self.songInQueueIsInPlayer(at: visibleIndexPath))
		}
		
		freshenTransportToolbar()
	}
}
