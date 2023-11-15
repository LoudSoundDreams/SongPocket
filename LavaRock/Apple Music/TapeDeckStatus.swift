//
//  TapeDeckStatus.swift
//  LavaRock
//
//  Created by h on 2022-05-12.
//

import MediaPlayer
import Combine

@MainActor
final class TapeDeckStatus: ObservableObject {
	private init() {
		freshen()
	}
	static let shared = TapeDeckStatus()
	@Published private(set) var current: Status? = nil
	
	struct Status {
		let isPlaying: Bool
	}
	
	func freshen() {
		let new: Status?
		defer { current = new }
		
		guard let player = MPMusicPlayerController.systemMusicPlayerIfAuthorized else {
			// Show disabled default state everywhere
			new = nil
			return
		}
		
		new = Status(isPlaying: player.playbackState == .playing)
	}
}
