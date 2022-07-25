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
	}
	
	static let shared = TapeDeckDisplay()
	@Published private(set) var status: Status? = nil
	
	private init() {
		freshenStatus()
	}
	
	func freshenStatus() {
		guard
			let player = TapeDeck.shared.player,
			!(Enabling.console && Reel.mediaItems.isEmpty)
		else {
			status = nil
			return
		}
		status = Status(
			isInPlayMode: player.playbackState == .playing)
	}
}
