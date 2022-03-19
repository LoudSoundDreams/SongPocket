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
	
	private(set) static var songs: [Song] = [] {
		didSet {
			tableView?.reloadData()
		}
	}
	
	static func set(
		songs: [Song],
		thenApplyTo player: MPMusicPlayerController
	) {
		self.songs = songs
		
		player.setQueue(
			with: MPMediaItemCollection(
				items: Self.songs.compactMap { $0.mpMediaItem() }))
	}
	
	static func append(
		songs: [Song],
		thenApplyTo player: MPMusicPlayerController
	) {
		self.songs.append(contentsOf: songs)
		
		player.append(
			MPMusicPlayerMediaItemQueueDescriptor(
				itemCollection: MPMediaItemCollection(
					items: songs.compactMap { $0.mpMediaItem() })))
	}
}
