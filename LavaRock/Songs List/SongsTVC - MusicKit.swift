//
//  SongsTVC - MusicKit.swift
//  LavaRock
//
//  Created by h on 2023-11-05.
//

import MediaPlayer

extension SongsTVC {
	func mediaItems() -> [MPMediaItem] {
		let items = Array(viewModel.libraryGroup().items)
		return items.compactMap { ($0 as? Song)?.mpMediaItem() }
	}
	
	// Time complexity: O(n), where “n” is the number of media items in the group.
	func mediaItems(startingAt: MPMediaItem) -> [MPMediaItem] {
		let result = mediaItems().drop(while: { mediaItem in
			mediaItem.persistentID != startingAt.persistentID
		})
		return Array(result)
	}
}
