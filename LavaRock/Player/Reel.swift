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
	
	static func allows_Play_Next() -> Bool {
		guard Enabling.inAppPlayer else {
			return true
		}
		guard let player = TapeDeck.shared.player else {
			return true
		}
		
		// Result: whether there’s at least 1 song after the current song
		if mediaItems.isEmpty {
			return false
		}
		let indexOfLastSong = mediaItems.count - 1
		let indexOfCurrentSong = player.indexOfNowPlayingItem // Note: `indexOfNowPlayingItem` returns 0 if the queue is empty
		return indexOfCurrentSong < indexOfLastSong
	}
}
