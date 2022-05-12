//
//  Reel.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

import MediaPlayer

//@MainActor // TO DO
struct Reel {
	private init() {}
	
	@MainActor
	static weak var table: UITableView? = nil
	
	private(set) static var mediaItems: [MPMediaItem] = [] {
		didSet {
			Task { await MainActor.run {
				NotificationCenter.default.post(
					name: .LRModifiedReel,
					object: nil)
				
				table?.reloadData()
			}}
		}
	}
	
	static func setMediaItems(_ newMediaItems: [MPMediaItem]) {
		mediaItems = newMediaItems
	}
}
