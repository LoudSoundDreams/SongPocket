//
//  TapeDeckDisplay.swift
//  LavaRock
//
//  Created by h on 2022-05-12.
//

import Foundation

@MainActor
final class TapeDeckDisplay: ObservableObject {
	struct Status {
		let isInPlayMode: Bool
		let isPlayingFirstSongInQueue: Bool
	}
	
	static let shared = TapeDeckDisplay()
	private init() {
		freshen()
	}
	
	@Published private(set) var currentStatus: Status? = nil
	
	final func freshen() {
		guard
			let player = TapeDeck.shared.player,
			!(Enabling.console && Reel.mediaItems.isEmpty)
		else {
			currentStatus = nil
			return
		}
		currentStatus = Status(
			isInPlayMode: player.playbackState == .playing,
			isPlayingFirstSongInQueue: player.indexOfNowPlayingItem == 0)
	}
}
