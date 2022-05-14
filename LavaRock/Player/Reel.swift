//
//  Reel.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

import MediaPlayer

extension Notification.Name {
	static let userChangedReelEmptiness = Self("user changed reel emptiness")
}

@MainActor
struct Reel {
	private init() {}
	
	static weak var table: UITableView? = nil
	
	private(set) static var mediaItems: [MPMediaItem] = [] {
		didSet {
			table?.reloadData()
			
			let wasEmpty = oldValue.isEmpty
			if wasEmpty != mediaItems.isEmpty {
				NotificationCenter.default.post(
					name: .userChangedReelEmptiness,
					object: nil)
			}
		}
	}
	
	static func setMediaItems(_ newMediaItems: [MPMediaItem]) {
		mediaItems = newMediaItems
	}
}
