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
	
	private(set) static var contents: [Song] = [] {
		didSet {
			Task { await MainActor.run {
				NotificationCenter.default.post(
					name: .LRSongQueueDidChange,
					object: nil)
				
				tableView?.reloadData() // TO DO
			}}
		}
	}
	
	static func setContents(_ newContents: [Song]) {
		contents = newContents
	}
	
	static func append(contentsOf newContents: [Song]) {
		contents.append(contentsOf: newContents)
	}
}
