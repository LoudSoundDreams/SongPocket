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
	private init() {
		freshen()
	}
	static let shared = TapeDeckStatus()
	
	struct Status {
		let isPlaying: Bool
	}
	
	@Published var current: Status? = nil
	
	func freshen() {
		let new_status: Status?
		defer {
			current = new_status
		}
		
		guard
			let player = TapeDeck.shared.player, // Have access to player
			!(Enabling.inAppPlayer && Reel.mediaItems.isEmpty) // In-app queue has at least one song
		else {
			// Show disabled default state everywhere
			new_status = nil
			return
		}
		
		new_status = Status(
			isPlaying: player.playbackState == .playing
		)
	}
}
