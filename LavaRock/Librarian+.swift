// 2024-12-18

import MediaPlayer

extension Librarian {
	static func merge_MediaPlayer_items(
		_ mpAlbums_unsorted: [MPMediaItemCollection]
	) async {
		let _merge = signposter.beginInterval("merge")
		defer { signposter.endInterval("merge", _merge) }
		
		/*
		 For each `LRAlbum`, determine whether it still corresponds to an album in the Apple Music library.
		 • If so, update its songs.
		 • If not, delete it.
		 Meanwhile, collect any Apple Music album we don’t have an `LRAlbum` for; we’ll add one.
		 
		 Add unfamiliar albums on top, most-recently-created on top. That puts them in the same order no matter when we run this merger. (Determine “date created” using the earliest “date added to library” among songs in the album.)
		 
		 When updating existing albums (by adding and removing songs), maintain the order of existing items.
		 When adding songs to an existing album: if the existing songs are in default order, maintain default order after adding songs. Otherwise, add them on top, most-recently-added on top.
		 
		 Deleting songs can change whether the remaining songs are in default order; deleting an album makes its ID unfamiliar. So procrastinate on those operations.
		 Delete `LRAlbum`s that now lack counterparts in the Apple Music library.
		 Delete empty containers.
		 */
		
		// Use MediaPlayer for album and song IDs.
		// Use MusicKit for all other metadata. `AppleLibrary.shared.mkSections_cache` should be ready by now.
		
		var to_update: [(LRAlbum, MPMediaItemCollection)] = [] // Order doesn’t matter.
		var to_delete: Set<UAlbum> = []
		var mpAlbum_with_uAlbum: [UAlbum: MPMediaItemCollection] = {
			let tuples = mpAlbums_unsorted.map { ($0.persistentID, $0) }
			return Dictionary(uniqueKeysWithValues: tuples)
		}()
		the_albums.forEach { lrAlbum in
			let uAlbum = lrAlbum.uAlbum
			if let mpAlbum_corresponding = mpAlbum_with_uAlbum[uAlbum] {
				to_update.append((lrAlbum, mpAlbum_corresponding))
				
				mpAlbum_with_uAlbum[uAlbum] = nil
			} else {
				to_delete.insert(lrAlbum.uAlbum)
			}
		}
		// `mpAlbum_with_uAlbum` now contains only unfamiliar albums.
		let to_add = Array(mpAlbum_with_uAlbum.values) // We’ll sort these later.
		
		let _fetch = signposter.beginInterval("fetch")
		for mpAlbum in to_add {
			for mpSong in mpAlbum.items {
				// This repeatedly updates an `@Observable` property, but SwiftUI doesn’t redraw dependent views for every update; maybe only once per turn of the run loop.
				await AppleLibrary.shared.cache_mkSong(uSong: mpSong.persistentID)
			}
		}
		for (_, mpAlbum) in to_update {
			for mpSong in mpAlbum.items {
				await AppleLibrary.shared.cache_mkSong(uSong: mpSong.persistentID)
			}
		}
		signposter.endInterval("fetch", _fetch)
		
		add_albums(to_add)
		update_albums(to_update)
		delete_albums(to_delete)
	}
	
	private static func add_albums(
		_ mpAlbums_unsorted: [MPMediaItemCollection]
	) {
		let mpAlbums_sorted = mpAlbums_unsorted.sorted { left, right in
			let info_left = AppleLibrary.shared.albumInfo(uAlbum: left.persistentID)
			let info_right = AppleLibrary.shared.albumInfo(uAlbum: right.persistentID)
			if info_left == nil && info_right == nil { return false }
			guard let info_right else { return true }
			guard let info_left else { return false }
			
			let date_left = info_left._date_first_added
			let date_right = info_right._date_first_added
			guard date_left != date_right else {
				let title_left = info_left._title
				let title_right = info_right._title
				return title_left.is_increasing_in_Finder(title_right)
			}
			guard let date_right else { return true }
			guard let date_left else { return false }
			return date_left > date_right
		}
		mpAlbums_sorted.reversed().forEach { mpAlbum in
			let lrAlbum_new = LRAlbum(
				uAlbum: mpAlbum.persistentID,
				uSongs: { // Sort them by our own track order for consistency.
					let uSongs_unsorted = mpAlbum.items.map { $0.persistentID }
					return uSongs_unsorted.sorted { left, right in
						let mk_left = AppleLibrary.shared.mkSongs_cache[left]
						let mk_right = AppleLibrary.shared.mkSongs_cache[right]
						if mk_left == nil && mk_right == nil { return false }
						guard let mk_right else { return true }
						guard let mk_left else { return false }
						
						return SongOrder.is_increasing_by_track(same_every_time: true, mk_left, mk_right)
					}
				}()
			)
			the_albums.insert(lrAlbum_new, at: 0)
			register_album(lrAlbum_new)
		}
	}
	
	private static func update_albums(
		_ lrAlbums_and_mpAlbums: [(LRAlbum, MPMediaItemCollection)]
	) {
		lrAlbums_and_mpAlbums.forEach { lrAlbum, mpAlbum in
			update_album(
				lrAlbum,
				to_match: Set(mpAlbum.items.map { $0.persistentID })
			)
		}
	}
	private static func update_album(
		_ lrAlbum: LRAlbum,
		to_match uSongs_fresh: Set<USong>
	) {
		let was_in_track_order: Bool = lrAlbum.uSongs.all_neighbors_satisfy {
			each, next in
			// Some `USong`s here might lack counterparts in the Apple Music library. If so, assume it was in track order.
			// Unfortunately, that means if we have existing songs E, G, F; and G lacks a counterpart, we think the album was in track order.
			guard
				let mk_left = AppleLibrary.shared.mkSongs_cache[each],
				let mk_right = AppleLibrary.shared.mkSongs_cache[next]
			else { return true }
			return SongOrder.is_increasing_by_track(same_every_time: true, mk_left, mk_right)
		}
		
		// If we have existing songs A, E, C; and the fresh songs are D, C, B, we want to insert D, B; and remove A, E.
		var uSongs_fresh = uSongs_fresh
		lrAlbum.uSongs.indices.reversed().forEach { i_uSong in
			let uSong = lrAlbum.uSongs[i_uSong]
			if uSongs_fresh.contains(uSong) {
				uSongs_fresh.remove(uSong)
			} else {
				lrAlbum.uSongs.remove(at: i_uSong)
				deregister_uSong(uSong)
			}
		}
		// `uSongs_fresh` now contains only unfamiliar songs.
		let to_add_unsorted = Array(uSongs_fresh)
		
		if was_in_track_order {
			to_add_unsorted.reversed().forEach { uSong in
				lrAlbum.uSongs.insert(uSong, at: 0)
				register_uSong(uSong, with: lrAlbum)
			}
			lrAlbum.uSongs.sort { left, right in
				let mk_left = AppleLibrary.shared.mkSongs_cache[left]
				let mk_right = AppleLibrary.shared.mkSongs_cache[right]
				if mk_left == nil && mk_right == nil { return false }
				guard let mk_right else { return true }
				guard let mk_left else { return false }
				
				return SongOrder.is_increasing_by_track(same_every_time: true, mk_left, mk_right)
			}
		} else {
			let to_add = to_add_unsorted.sorted { left, right in
				let mk_left = AppleLibrary.shared.mkSongs_cache[left]
				let mk_right = AppleLibrary.shared.mkSongs_cache[right]
				if mk_left == nil && mk_right == nil { return false }
				guard let mk_right else { return true }
				guard let mk_left else { return false }
				
				let date_left: Date? = mk_left.libraryAddedDate
				let date_right: Date? = mk_right.libraryAddedDate
				if date_left == date_right {
					return SongOrder.is_increasing_by_track(same_every_time: true, mk_left, mk_right)
				}
				guard let date_right else { return true }
				guard let date_left else { return false }
				return date_left > date_right
			}
			to_add.reversed().forEach { uSong in
				lrAlbum.uSongs.insert(uSong, at: 0)
				register_uSong(uSong, with: lrAlbum)
			}
		}
	}
	
	private static func delete_albums(
		_ to_delete: Set<UAlbum>
	) {
		// Suboptimal; unnecessarily checks albums we added or updated just earlier.
		the_albums.indices.reversed().forEach { i_album in
			let uAlbum = the_albums[i_album].uAlbum
			if to_delete.contains(uAlbum) {
				the_albums.remove(at: i_album)
				deregister_uAlbum(uAlbum)
			}
		}
	}
}
