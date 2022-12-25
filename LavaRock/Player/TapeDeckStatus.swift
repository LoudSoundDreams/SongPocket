//
//  TapeDeckStatus.swift
//  LavaRock
//
//  Created by h on 2022-05-12.
//

import Combine
import CoreData

@MainActor
final class TapeDeckStatus: ObservableObject {
	struct Status {
		let isPlaying: Bool
		let now_playing_SongID: SongID
	}
	
	private init() {
		freshen()
	}
	static let shared = TapeDeckStatus()
	
	@Published var current: Status? = nil
	
	func freshen() {
		let new_status: Status?
		defer {
			current = new_status
		}
		
		guard
			let player = TapeDeck.shared.player, // Have access to player
			let songID = player.now_playing_SongID(),
			!(Enabling.inAppPlayer && Reel.mediaItems.isEmpty) // In-app queue has at least one song
		else {
			// Show disabled default state everywhere
			new_status = nil
			return
		}
		
		new_status = Status(
			isPlaying: player.playbackState == .playing,
			now_playing_SongID: songID)
	}
}