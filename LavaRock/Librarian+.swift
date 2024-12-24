// 2024-12-18

import MediaPlayer

extension Librarian {
	static func merge_MediaPlayer_items(
		_ mpAlbums_unsorted: [MPMediaItemCollection]
	) async {
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
		var to_remove: [LRAlbum] = [] // Order doesn’t matter.
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
				to_remove.append(lrAlbum)
			}
		}
		// `mpAlbum_with_uAlbum` now contains only unfamiliar albums.
		let to_insert = Array(mpAlbum_with_uAlbum.values) // We’ll sort these later.
		
		for mpAlbum in to_insert {
			for mpSong in mpAlbum.items {
				await AppleLibrary.shared.cache_mkSong(uSong: mpSong.persistentID) // 22do: Does this repeatedly redraw SwiftUI views?
			}
		}
		for (lrAlbum, mpAlbum) in to_update {
			for lrSong in lrAlbum.lrSongs {
				let uSong_existing = lrSong.uSong
				await AppleLibrary.shared.cache_mkSong(uSong: uSong_existing)
			}
			for mpSong in mpAlbum.items {
				let uSong_fresh = mpSong.persistentID
				await AppleLibrary.shared.cache_mkSong(uSong: uSong_fresh)
			}
		}
		
		insert_albums(to_insert)
		update_albums(to_update)
		remove_albums(to_remove)
	}
	
	private static func insert_albums(
		_ mpAlbums_unsorted: [MPMediaItemCollection]
	) {
		let mpAlbums_sorted = mpAlbums_unsorted.sorted {
			left, right in
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
		mpAlbums_sorted.reversed().forEach { mpAlbum in
			register_album(
				LRAlbum(
					uAlbum: mpAlbum.persistentID,
					songs: { // Sort them by our own track order for consistency.
						let uSongs_unsorted = mpAlbum.items.map { $0.persistentID }
						let uSongs_by_track_order = uSongs_unsorted.sorted {
							left, right in
							guard let mk_right = AppleLibrary.shared.mkSongs_cache[right]
							else { return true }
							guard let mk_left = AppleLibrary.shared.mkSongs_cache[left]
							else { return false }
							return SongOrder.is_in_track_order(strict: true, mk_left, mk_right)
						}
						return uSongs_by_track_order.map { LRSong(uSong: $0) }
					}()
				)
			)
		}
	}
	
	private static func update_albums(
		_ lrAlbums_and_mpAlbums: [(LRAlbum, MPMediaItemCollection)]
	) {
		lrAlbums_and_mpAlbums.forEach { lrAlbum, mpAlbum in
			update_album(lrAlbum, to_match: mpAlbum)
		}
	}
	private static func update_album(
		_ lrAlbum: LRAlbum,
		to_match mpAlbum: MPMediaItemCollection
	) {
		let was_in_track_order: Bool = lrAlbum.lrSongs.all_neighbors_satisfy {
			each, next in
			// Some `LRSong`s here might lack counterparts in the Apple Music library. If so, assume it was in track order.
			// 2do: That means if we have existing songs E, G, F; and G lacks a counterpart, we think the album was in track order.
			guard
				let mk_left = AppleLibrary.shared.mkSongs_cache[each.uSong],
				let mk_right = AppleLibrary.shared.mkSongs_cache[next.uSong]
			else { return true }
			return SongOrder.is_in_track_order(strict: true, mk_left, mk_right)
		}
		
		// If we have existing songs A, E, C; and the fresh songs are D, C, B, we want to insert D, B; and remove A, E.
		var uSongs_fresh: Set<USong> = Set(mpAlbum.items.map { $0.persistentID })
		lrAlbum.lrSongs.indices.reversed().forEach { i_lrSong in
			let uSong = lrAlbum.lrSongs[i_lrSong].uSong
			if uSongs_fresh.contains(uSong) {
				uSongs_fresh.remove(uSong)
			} else {
				lrAlbum.lrSongs.remove(at: i_lrSong)
				// 22do: Remove unused dictionary entries.
			}
		}
		// `uSongs_fresh` now contains only unfamiliar songs.
		let to_insert_unsorted = Array(uSongs_fresh)
		
		if was_in_track_order {
			let to_insert = to_insert_unsorted.sorted { left, right in // For consistency.
				guard let mk_right = AppleLibrary.shared.mkSongs_cache[right]
				else { return true }
				guard let mk_left = AppleLibrary.shared.mkSongs_cache[left]
				else { return false }
				return SongOrder.is_in_track_order(strict: true, mk_left, mk_right)
			}
			to_insert.reversed().forEach { uSong in
				register_song(LRSong(uSong: uSong), in: lrAlbum)
			}
			lrAlbum.lrSongs.sort { lr_left, lr_right in
				guard let mk_right = AppleLibrary.shared.mkSongs_cache[lr_right.uSong]
				else { return true }
				guard let mk_left = AppleLibrary.shared.mkSongs_cache[lr_left.uSong]
				else { return false }
				return SongOrder.is_in_track_order(strict: true, mk_left, mk_right)
			}
		} else {
			let to_insert = to_insert_unsorted.sorted { left, right in
				guard let mk_right = AppleLibrary.shared.mkSongs_cache[right]
				else { return true }
				guard let mk_left = AppleLibrary.shared.mkSongs_cache[left]
				else { return false }
				guard mk_left.libraryAddedDate != mk_right.libraryAddedDate else {
					return SongOrder.is_in_track_order(strict: true, mk_left, mk_right)
				}
				guard let date_right = mk_right.libraryAddedDate else { return true }
				guard let date_left = mk_left.libraryAddedDate else { return false }
				return date_left > date_right
			}
			to_insert.reversed().forEach { uSong in
				register_song(LRSong(uSong: uSong), in: lrAlbum)
			}
		}
	}
	
	private static func remove_albums(
		_ to_remove: [LRAlbum]
	) {
		guard let the_crate else { return }
		
		let uAlbums_to_remove = Set(to_remove.map { $0.uAlbum })
		// 2do: Skip checking albums at the beginning that we created just now.
		the_crate.lrAlbums.indices.reversed().forEach { i_album in
			let album = the_crate.lrAlbums[i_album]
			if uAlbums_to_remove.contains(album.uAlbum) {
				the_crate.lrAlbums.remove(at: i_album)
				// 22do: Remove unused dictionary entries.
			}
		}
	}
}
