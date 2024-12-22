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
			guard
				let rep_right = right.representativeItem,
				let info_right = AppleLibrary.shared.albumInfo(mpid: MPIDAlbum(rep_right.albumPersistentID))
			else { return true }
			guard
				let rep_left = left.representativeItem,
				let info_left = AppleLibrary.shared.albumInfo(mpid: MPIDAlbum(rep_left.albumPersistentID))
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
		mpAlbums_by_recently_created.forEach { mpAlbum in
			let int64 = MPIDAlbum(bitPattern: mpAlbum.persistentID) // TO DO
			let album = register_album(mpid: int64)
			mpAlbum.items.shuffled().forEach { mpSong in
				let int64_song = MPIDSong(bitPattern: mpSong.persistentID) // TO DO
				register_song(mpid: int64_song, in: album)
			}
		}
		
		debug_Print()
	}
}
