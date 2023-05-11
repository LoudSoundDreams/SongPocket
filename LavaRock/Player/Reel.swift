//
//  Reel.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

import MediaPlayer

@MainActor
struct Reel {
	private init() {}
	
	private(set) static var mediaItems: [MPMediaItem] = [] {
		didSet {
			if oldValue.isEmpty != mediaItems.isEmpty {
				NotificationCenter.default.post(
					name: .userChangedReelEmptiness,
					object: nil)
			}
		}
	}
	
	static func setMediaItems(_ newMediaItems: [MPMediaItem]) {
		mediaItems = newMediaItems
	}
	
	// Result: whether there’s at least 1 song after the current song
	static func allows_Play_Next() -> Bool {
		guard let player = TapeDeck.shared.player else {
			return true
		}
		
		guard Enabling.inAppPlayer else {
			return true
		}
		
		let currentIndex = player.indexOfNowPlayingItem // When nothing is in the player, this is 0, which weirdens the comparison
		let lastIndexInQueue = mediaItems.count - 1
		if mediaItems.isEmpty {
			return false
		}
		return currentIndex < lastIndexInQueue
	}
}
