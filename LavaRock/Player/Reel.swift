//
//  Reel.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

import MediaPlayer

extension Notification.Name {
	static let modifiedReel = Self("modified reel")
}

@MainActor
struct Reel {
	private init() {}
	
	static weak var table: UITableView? = nil
	
	private(set) static var mediaItems: [MPMediaItem] = [] {
		didSet {
			NotificationCenter.default.post( // TO DO: Only post a notification when `mediaItems.isEmpty` changed.
				name: .modifiedReel,
				object: nil)
			
			table?.reloadData()
		}
	}
	
	static func setMediaItems(_ newMediaItems: [MPMediaItem]) {
		mediaItems = newMediaItems
	}
}
