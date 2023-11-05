//
//  SongsTVC - MusicKit.swift
//  LavaRock
//
//  Created by h on 2023-11-05.
//

import MediaPlayer

extension SongsTVC {
	// Time complexity: O(n), where “n” is the number of media items in the group.
	func mediaItemsInFirstGroup(
		startingAt startingMediaItem: MPMediaItem
	) -> [MPMediaItem] {
		let result = mediaItems().drop(while: { mediaItem in
			mediaItem.persistentID != startingMediaItem.persistentID
		})
		return Array(result)
	}
}
