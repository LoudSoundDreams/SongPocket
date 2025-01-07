// 2024-12-18

import MediaPlayer

extension Librarian {
	static func merge_MediaPlayer_items(
		_ mpSongs_by_album_then_track: [MPMediaItem]
	) async {
		let _merge = signposter.beginInterval("merge")
		defer { signposter.endInterval("merge", _merge) }
		
		// Use MediaPlayer for album and song IDs.
		// Ideally, use MusicKit for all other metadata.
		
		// Group fresh songs by album, just in case.
		let dict_fresh: [UAlbum: [MPMediaItem]] = { // Scrambles `UAlbum`s, but we only care about their order when adding albums (which we’ll do by date first added).
			var result: [UAlbum: [MPMediaItem]] = [:]
			mpSongs_by_album_then_track.forEach { mpSong in
				let uAlbum = mpSong.albumPersistentID
				var uSongs_fresh = result[uAlbum] ?? []
				uSongs_fresh.append(mpSong)
				result[uAlbum] = uSongs_fresh
			}
			return result
		}()
		
		/*
		 For each fresh album, determine whether we have an existing `LRAlbum` corresponding to it.
		 • If so, update its songs.
		 • If not, add one.
		 Meanwhile, collect `LRAlbum`s that no longer correspond to an album in the Apple Music library. Delete them.
		 */
		var lrAlbums_existing: [UAlbum: LRAlbum] = {
			let tuples: [(UAlbum, LRAlbum)] = the_albums.map {( $0.uAlbum, $0 )}
			return Dictionary(uniqueKeysWithValues: tuples)
		}()
		var to_add: [(LRAlbum, date_created: Date?)] = [] // We’ll sort these later.
		var to_update: [(LRAlbum, fresh: [USong])] = [] // Order of `USong`s matters. Order of albums doesn’t.
		dict_fresh.forEach { (uAlbum, mpSongs) in
			if let existing = lrAlbums_existing[uAlbum] {
				to_update.append((
					existing,
					mpSongs.map { $0.persistentID }
				))
				
				lrAlbums_existing[uAlbum] = nil
			} else {
				let tuple: (LRAlbum, Date?) = {
					let lrAlbum = LRAlbum(uAlbum: uAlbum, uSongs: [])
					var date_created: Date? = nil
					mpSongs.forEach { mpSong in
						lrAlbum.uSongs.append(mpSong.persistentID)
						
						let date_added: Date = mpSong.dateAdded
						guard let earliest_so_far = date_created else {
							date_created = date_added
							return
						}
						if date_added < earliest_so_far {
							date_created = date_added
						}
					}
					return (lrAlbum, date_created)
				}()
				to_add.append(tuple)
			}
		}
		// Now, `lrAlbums_existing` contains only albums no longer in the Apple Music library.
		let to_delete = Set(lrAlbums_existing.keys) // Order doesn’t matter.
		
		add_albums(to_add)
		await update_albums(to_update)
		
		delete_albums(to_delete)
	}
	
	private static func add_albums(
		_ tuples_unsorted: [(LRAlbum, date_created: Date?)]
	) {
		/*
		 Add albums on top, most-recently-created on top. That puts them in the same order no matter when we run this merger.
		 Determine “date created” using the earliest “date added to library” among songs in the album.
		 */
		let tuples_by_recently_created = tuples_unsorted.sorted { left, right in
			let date_left = left.date_created
			let date_right = right.date_created
			if date_left == date_right { return false }
			guard let date_right else { return false }
			guard let date_left else { return true }
			return date_left > date_right
		}
		tuples_by_recently_created.reversed().forEach { tuple in
			let lrAlbum = tuple.0
			the_albums.insert(lrAlbum, at: 0)
			register_album(lrAlbum)
		}
	}
	
	private static func update_albums(
		_ tuples: [(LRAlbum, fresh: [USong])]
	) async {
		for (lrAlbum, uSongs) in tuples {
			await update_album(lrAlbum, to_match: uSongs)
		}
	}
	private static func update_album(
		_ lrAlbum: LRAlbum,
		to_match uSongs_fresh: [USong]
	) async {
		/*
		 Give each `LRAlbum` the same songs as the fresh album.
		 • If the existing songs are in default order, maintain default order after adding songs.
		 • Otherwise, add songs on top, most-recently-added on top.
		 */
		
		let fresh_set = Set(uSongs_fresh)
		let was_in_original_order: Bool = { // Deleting songs can change whether the remaining ones are in original order, so procrastinate on that.
			// Some existing `USong`s might lack counterparts in the Apple Music library; if so, assume they were in original order. Unfortunately, that means if we have existing songs E, G, F; and G is no longer in the Apple Music library, we think the album was in original order.
			let existing_to_keep = lrAlbum.uSongs.filter { fresh_set.contains($0) }
			var i_keep = 0
			var i_fresh = 0 // `uSongs_fresh` has at least as many elements as `existing_to_keep`.
			while i_keep < existing_to_keep.count {
				/*
				 Every existing song here is also in `uSongs_fresh`.
				 Iterate through both simultaneously: `existing_to_keep` is the checklist, and `uSongs_fresh` is the information source.
				 Pretend we have existing songs C, A; and fresh songs A, B, C, D.
				 See when each existing song occurs among the fresh ones; we want to know whether they’re in the same order.
				 If the two songs we’re pointing to are the same, advance both pointers.
				 If we reach the end of the existing songs, then they were in original order.
				 If the two songs we’re pointing to are different, continue with the next fresh song.
				 If we run out of fresh songs, then the existing songs weren’t in original order.
				 */
				let keep = existing_to_keep[i_keep]
				while true {
					guard i_fresh < uSongs_fresh.count else { return false }
					let fresh = uSongs_fresh[i_fresh]
					i_fresh += 1
					if fresh == keep { break }
				}
				i_keep += 1
			}
			return true
		}()
		
		// If the fresh songs are B, C, D; and we have existing songs A, E, C, we want to add B, D; and delete A, E.
		var to_add = fresh_set // Whittle down. If the existing songs were in original order, we won’t even need this.
		lrAlbum.uSongs.indices.reversed().forEach { i_uSong in
			let existing = lrAlbum.uSongs[i_uSong]
			if to_add.contains(existing) {
				to_add.remove(existing)
			} else {
				lrAlbum.uSongs.remove(at: i_uSong)
				deregister_uSong(existing)
			}
		}
		
		if was_in_original_order {
			lrAlbum.uSongs = uSongs_fresh
			lrAlbum.uSongs.forEach {
				register_uSong($0, with: lrAlbum)
			}
		} else {
			for uSong in to_add {
				await AppleLibrary.shared.cache_mkSong(uSong: uSong) // This repeatedly updates an `@Observable` property, but SwiftUI doesn’t redraw dependent views for every update; maybe only once per turn of the run loop.
			}
			let to_add_sorted = to_add.sorted { left, right in
				let mk_left = AppleLibrary.shared.mkSongs_cache[left]
				let mk_right = AppleLibrary.shared.mkSongs_cache[right]
				if mk_left == nil && mk_right == nil { return false }
				guard let mk_right else { return true }
				guard let mk_left else { return false }
				
				let date_left: Date? = mk_left.libraryAddedDate
				let date_right: Date? = mk_right.libraryAddedDate
				if date_left == date_right { return false }
				guard let date_right else { return true }
				guard let date_left else { return false }
				return date_left > date_right
			}
			to_add_sorted.reversed().forEach { uSong in
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
