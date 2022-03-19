//
//  SongQueue.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

import MediaPlayer

struct SongQueue {
	private init() {}
	
	static weak var tableView: UITableView? = nil
	
	private(set) static var contents: [Song] = [] {
		didSet {
			tableView?.reloadData()
		}
	}
	
	static func set(
		songs: [Song],
		thenApplyTo player: MPMusicPlayerController
	) {
		contents = songs
		
		player.setQueue(with: songs)
	}
	
	static func append(
		songs: [Song],
		thenApplyTo player: MPMusicPlayerController
	) {
		contents.append(contentsOf: songs)
		
		player.appendToQueue(songs)
	}
}
