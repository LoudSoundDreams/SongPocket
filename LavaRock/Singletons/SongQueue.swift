//
//  SongQueue.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

import MediaPlayer

//@MainActor // TO DO
struct SongQueue {
	private init() {}
	
	@MainActor
	static weak var tableView: UITableView? = nil
	
	private(set) static var mediaItems: [MPMediaItem] = [] {
		didSet {
			Task { await MainActor.run {
				NotificationCenter.default.post(
					name: .LRSongQueueDidChange,
					object: nil)
				
				tableView?.reloadData() // TO DO
			}}
		}
	}
	
	static func setMediaItems(_ newMediaItems: [MPMediaItem]) {
		mediaItems = newMediaItems
	}
}
