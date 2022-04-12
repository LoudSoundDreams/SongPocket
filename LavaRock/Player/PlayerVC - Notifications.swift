//
//  PlayerVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2022-03-27.
//

import Foundation

extension PlayerVC: PlayerReflecting {
	func playbackStateDidChange() {
		freshenNowPlayingIndicatorsAndPlaybackToolbar_PVC()
	}
}
extension PlayerVC: PlaybackToolbarManaging {}
extension PlayerVC {
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
