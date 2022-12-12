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
		let isPlaying: Bool
	}
	
	static let shared = TapeDeckDisplay()
	@Published private(set) var status: Status? = nil
	
	private init() {
		freshenStatus()
	}
	
	func freshenStatus() {
		guard
			let player = TapeDeck.shared.player, // Have access to player
			!(Enabling.inAppPlayer && Reel.mediaItems.isEmpty) // At least one song in in-app queue
		else {
			// Show disabled default state everywhere
			status = nil
			return
		}
		status = Status(
			isPlaying: player.playbackState == .playing)
	}
}
