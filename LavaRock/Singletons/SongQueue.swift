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
			tableView?.reloadData() // TO DO
		}
	}
	
	static func setContents(_ newContents: [Song]) {
		contents = newContents
	}
	
	static func append(contentsOf newContents: [Song]) {
		contents.append(contentsOf: newContents)
	}
}
