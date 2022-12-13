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
	}
	
	static let shared = TapeDeckStatus()
	@Published private(set) var current: Status? = nil
	
	private init() {
		freshenStatus()
	}
	
	func freshenStatus() {
		guard
			let player = TapeDeck.shared.player, // Have access to player
			!(Enabling.inAppPlayer && Reel.mediaItems.isEmpty) // In-app queue has at least one song
		else {
			// Show disabled default state everywhere
			current = nil
			return
		}
		current = Status(
			isPlaying: player.playbackState == .playing)
	}
}
