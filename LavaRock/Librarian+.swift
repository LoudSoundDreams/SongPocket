// 2024-12-18

import MediaPlayer

extension Librarian {
	static func merge_MediaPlayer_items(
		_ mpAlbums_unsorted: [MPMediaItemCollection]
	) {
		/*
		 For each `LRAlbum`, determine whether it still corresponds to an album in the Apple Music library.
		 • If so, update its songs.
		 • If not, delete it.
		 Meanwhile, collect any Apple Music album we don’t have an `LRAlbum` for; we’ll create one.
		 
		 Insert unfamiliar albums on top, most-recently-created on top. That puts them in the same order no matter when we run this merger. (Determine “date created” using the earliest “date added to library” among songs in the album.)
		 
		 When modifying existing albums (by adding and removing songs), maintain the order of existing items.
		 When adding songs to an existing album: if the existing songs are in default order, maintain default order after adding songs. Otherwise, insert them on top, most-recently-added on top.
		 
		 Removing songs can change whether the remaining songs are in default order; removing an album makes its ID unfamiliar. So procrastinate on those operations.
		 Remove `LRAlbum`s and `LRSong`s that now lack counterparts in the Apple Music library. Remove empty `LRAlbum`s and `LRCrate`s.
		 */
		
		// Use MediaPlayer for album and song IDs.
		// Use MusicKit for all other metadata. `AppleLibrary.shared.mkSections_cache` should be ready by now.
		
		let lrAlbums_existing: [LRAlbum] = the_crate?.lrAlbums ?? []
		var to_update: [(LRAlbum, MPMediaItemCollection)] = [] // Order doesn’t matter.
		var to_delete: [LRAlbum] = [] // Order doesn’t matter.
		var mpAlbum_with_uAlbum: [UAlbum: MPMediaItemCollection] = {
			let tuples = mpAlbums_unsorted.map { ($0.persistentID, $0) }
			return Dictionary(uniqueKeysWithValues: tuples)
		}()
		lrAlbums_existing.forEach { lrAlbum in
			let uAlbum = lrAlbum.uAlbum
			if let mpAlbum_corresponding = mpAlbum_with_uAlbum[uAlbum] {
				to_update.append((lrAlbum, mpAlbum_corresponding))
				
				mpAlbum_with_uAlbum[uAlbum] = nil
			} else {
				to_delete.append(lrAlbum)
			}
		}
		// `mpAlbum_with_uAlbum` now contains only unfamiliar albums.
		let to_create = mpAlbum_with_uAlbum
		
		Print()
		Print("update:")
		to_update.forEach { (lrAlbum, mpAlbum) in
			Print("\(mpAlbum.persistentID) • \(lrAlbum.uAlbum), \(AppleLibrary.shared.albumInfo(uAlbum: lrAlbum.uAlbum)?._title)")
		}
		Print()
		Print("delete:")
		to_delete.forEach { lrAlbum in
			Print(lrAlbum.uAlbum, AppleLibrary.shared.albumInfo(uAlbum: lrAlbum.uAlbum)?._title)
		}
		Print()
		Print("create:")
		to_create.forEach { (uAlbum, mpAlbum) in
			Print(uAlbum, mpAlbum.representativeItem?.albumTitle)
		}
		
		
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
