//
//  ConsoleVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2022-03-27.
//

import Foundation

extension ConsoleVC: PlayerReflecting {
	func playbackStateDidChange() {
		freshenNowPlayingIndicatorsAndPlaybackToolbar_PVC()
	}
}
extension ConsoleVC: PlaybackToolbarManaging {}
extension ConsoleVC {
	// MARK: - Player
	
	final func freshenNowPlayingIndicatorsAndPlaybackToolbar_PVC() {
		queueTable.indexPathsForVisibleRowsNonNil.forEach { visibleIndexPath in
			guard let cell = queueTable.cellForRow(
				at: visibleIndexPath) as? NowPlayingIndicating
			else { return }
			cell.indicateNowPlaying(
				isInPlayer: Self.songInQueueIsInPlayer(at: visibleIndexPath))
		}
		
		freshenPlaybackToolbar()
	}
}
