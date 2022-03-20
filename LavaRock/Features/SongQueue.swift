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
	
	static var contents: [Song] = [] {
		didSet {
			tableView?.reloadData()
		}
	}
}
