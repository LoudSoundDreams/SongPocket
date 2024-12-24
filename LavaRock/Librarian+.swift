// 2024-12-18

import MusicKit
import MediaPlayer

extension Librarian {
	static func merge_MediaPlayer_items(
		_ mpAlbums_unsorted: [MPMediaItemCollection]
	) {
		/*
		 For each album in the user’s Apple Music library, determine whether we already have a corresponding `LRAlbum` tracking its ID and position.
		 
		 Insert unfamiliar albums on top, most-recently-created on top. That puts them in the same order no matter when we run this merger. (Determine “date created” using the earliest “date added to library” among songs in the album.)
		 
		 When modifying existing albums (by adding and removing songs), maintain the order of existing items.
		 When adding songs to an existing album: if the existing songs are in default order, maintain default order after adding songs. Otherwise, insert them on top, most-recently-added on top.
		 
		 Removing songs can change whether the remaining songs are in default order; removing an album makes its ID unfamiliar. So procrastinate on those operations.
		 Remove `LRAlbum`s and `LRSong`s that now lack counterparts in the Apple Music library. Remove empty `LRAlbum`s and `LRCrate`s.
		 */
		
		// Use MediaPlayer for album and song IDs.
		// Use MusicKit for all other metadata. `AppleLibrary.shared.mkSections_cache` should be ready by now.
		
		let mpAlbums_by_recently_created = mpAlbums_unsorted.sorted { left, right in
			guard let info_right = AppleLibrary.shared.albumInfo(uAlbum: right.persistentID)
			else { return true }
			guard let info_left = AppleLibrary.shared.albumInfo(uAlbum: left.persistentID)
			else { return false }
			
			let date_left: Date? = info_left._date_first_added
			let date_right: Date? = info_right._date_first_added
			
			guard date_left != date_right else {
				return info_left._title.precedes_in_Finder(info_right._title)
			}
			guard let date_right else { return true }
			guard let date_left else { return false }
			return date_left > date_right
		}
		
		if let the_crate {
			deregister_crate(the_crate)
		}
		mpAlbums_by_recently_created.forEach { mpAlbum in
			register_album(LRAlbum(
				uAlbum: mpAlbum.persistentID,
				songs: mpAlbum.items.shuffled().map { mpSong in
					LRSong(uSong: mpSong.persistentID)
				})
			)
		}
	}
}
