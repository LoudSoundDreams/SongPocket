// 2024-12-18

import MediaPlayer

extension Librarian {
	static func merge_MediaPlayer_items(
		_ mpAlbums_unsorted: [MPMediaItemCollection]
	) {
		// For each album in the user’s Apple Music library, determine whether we already have a corresponding `LRAlbum` tracking its ID and position.
		
		// Insert unfamiliar albums on top, most-recently-created on top. That puts them in the same order no matter when we run this merger. (Determine “date created” using the earliest “date added to library” among songs in the album.)
		
		// When modifying existing albums (by adding and removing songs), maintain the order of existing items.
		// When adding songs to an existing album: if the existing songs are in default order, maintain default order after adding songs. Otherwise, insert them on top, most-recently-added on top.
		
		// Removing songs can change whether the remaining songs are in default order; removing an album means its ID becomes unfamiliar. So procrastinate on those operations.
		// Remove `LRAlbum`s and `LRSong`s that now lack counterparts in the Apple Music library; that should automatically leave no empty `LRAlbum`s. Remove empty `LRCrate`s.
		
		// TO DO
		if let the_lrCrate = the_lrCrate {
			remove_lrCrate(the_lrCrate)
		}
		
		let mpAlbums_by_recently_created = mpAlbums_unsorted.sorted { left, right in
			left.items.count > right.items.count
		}
		mpAlbums_by_recently_created.forEach { mpAlbum in
			Print()
			Print("album")
			Print(mpAlbum.persistentID, mpAlbum.count)
			let int64 = MPIDAlbum(bitPattern: mpAlbum.persistentID) // TO DO
			Print(int64)
			
			let lrAlbum = append_lrAlbum(mpid: int64)
			mpAlbum.items.shuffled().forEach { mpSong in
				Print("song")
				Print(mpSong.persistentID, mpSong.title ?? "no title")
				let int64_song = MPIDSong(bitPattern: mpSong.persistentID) // TO DO
				Print(int64_song)
				
				append_lrSong(mpid: int64_song, in: lrAlbum)
			}
		}
	}
}
