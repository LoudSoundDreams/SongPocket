// 2024-09-04

import os

final class LRCrate {
	let title: String
	var lrAlbums: [LRAlbum] = []
	init(title: String) {
		self.title = title
	}
}
final class LRAlbum {
	let uAlbum: UAlbum
	var uSongs: [USong] = []
	init(uAlbum: UAlbum, uSongs: [USong]) {
		self.uAlbum = uAlbum
		self.uSongs = uSongs
	}
}

@MainActor struct Librarian {
	static let signposter = OSSignposter(subsystem: "librarian", category: .pointsOfInterest)
	
	// Browse
	private(set) static var the_crate: LRCrate?
	
	// Search
	private(set) static var album_with_uAlbum: [UAlbum: WeakRef<LRAlbum>] = [:]
	private(set) static var uSongs_known: Set<USong> = []
	private(set) static var album_containing_uSong: [USong: WeakRef<LRAlbum>] = [:]
	
	// Register
	static func reset_the_crate() {
		the_crate = LRCrate(title: InterfaceText._tilde)
	}
	static func register_album(
		_ album_new: LRAlbum
	) {
		album_with_uAlbum[album_new.uAlbum] = WeakRef(album_new)
		album_new.uSongs.forEach { uSong in
			register_uSong(uSong, with: album_new)
		}
	}
	static func register_uSong(
		_ uSong: USong,
		with album_target: LRAlbum
	) {
		uSongs_known.insert(uSong)
		album_containing_uSong[uSong] = WeakRef(album_target)
	}
	
	// Deregister
	static func deregister_uAlbum(_ uAlbum: UAlbum) {
		let album = album_with_uAlbum[uAlbum]?.referencee
		album_with_uAlbum[uAlbum] = nil
		album?.uSongs.forEach { uSong in
			deregister_uSong(uSong)
		}
	}
	static func deregister_uSong(_ uSong: USong) {
		uSongs_known.remove(uSong)
		album_containing_uSong[uSong] = nil
	}
	
	// Persist
	static func save() {
		guard let the_crate else { return }
		
		Disk.save_crates([the_crate])
	}
	static func load() {
		guard let crate_loaded = Disk.load_crates().first else { return }
		
		// Give the crate the default title.
		reset_the_crate(); let the_crate = the_crate!
		the_crate.lrAlbums = crate_loaded.lrAlbums
		the_crate.lrAlbums.forEach { album in
			register_album(album)
		}
	}
	
	// Promote
	static func promote_albums(
		_ uAlbums_selected: Set<UAlbum>,
		to_limit: Bool
	) {
		guard let crate = the_crate else { return }
		let rs_to_promote = crate.lrAlbums.indices(where: { album in
			uAlbums_selected.contains(album.uAlbum)
		})
		let target: Int? = (
			to_limit
			? 0
			: target_promoting(rs_to_promote)
		)
		guard let target else { return }
		crate.lrAlbums.moveSubranges(rs_to_promote, to: target)
	}
	static func promote_songs(
		_ uSongs_selected: Set<USong>,
		to_limit: Bool
	) {
		guard let album = album_containing_uSongs(uSongs_selected) else { return } // Verify that the selected songs are in the same album. Find that album.
		let rs_to_promote = album.uSongs.indices(where: { uSong in
			uSongs_selected.contains(uSong)
		})
		let target: Int? = (
			to_limit
			? 0
			: target_promoting(rs_to_promote)
		)
		guard let target else { return }
		album.uSongs.moveSubranges(rs_to_promote, to: target)
	}
	private static func target_promoting(
		_ rangeSet: RangeSet<Int>
	) -> Int? {
		guard let front = rangeSet.ranges.first?.first else { return nil }
		if rangeSet.ranges.count == 1 { // If contiguous …
			return max(front-1, 0) // … 1 step toward beginning, but stay in bounds.
		} else {
			return front // … make contiguous starting at front.
		}
	}
	
	// Demote
	static func demote_albums(
		_ uAlbums_selected: Set<UAlbum>,
		to_limit: Bool
	) {
		guard let crate = the_crate else { return }
		let rs_to_demote = crate.lrAlbums.indices(where: { album in
			uAlbums_selected.contains(album.uAlbum)
		})
		let target: Int? = (
			to_limit
			? crate.lrAlbums.count-1
			: target_demoting(
				rs_to_demote,
				index_max: crate.lrAlbums.count-1)
		)
		guard let target else { return }
		crate.lrAlbums.moveSubranges(rs_to_demote, to: target+1) // This method puts the last in-range element before the `to:` index.
	}
	static func demote_songs(
		_ uSongs_selected: Set<USong>,
		to_limit: Bool
	) {
		guard let album = album_containing_uSongs(uSongs_selected) else { return }
		let rs_to_demote = album.uSongs.indices(where: { uSong in
			uSongs_selected.contains(uSong)
		})
		let target: Int? = (
			to_limit
			? album.uSongs.count-1
			: target_demoting(
				rs_to_demote,
				index_max: album.uSongs.count-1)
		)
		guard let target else { return }
		album.uSongs.moveSubranges(rs_to_demote, to: target+1)
	}
	private static func target_demoting(
		_ rangeSet: RangeSet<Int>,
		index_max: Int
	) -> Int? {
		guard let back = rangeSet.ranges.last?.last else { return nil }
		if rangeSet.ranges.count == 1 {
			return min(back+1, index_max)
		} else {
			return back
		}
	}
	
	// Sort
	static func sort_albums(
		_ uAlbums_selected: Set<UAlbum>,
		by albumOrder: AlbumOrder
	) {
		guard let crate = the_crate else { return }
		let albums_selected_sorted: [LRAlbum] = {
			let albums_selected = crate.lrAlbums.filter {
				uAlbums_selected.contains($0.uAlbum)
			}
			switch albumOrder {
				case .reverse: return albums_selected.reversed()
				case .random: return albums_selected.in_any_other_order { $0.uAlbum == $1.uAlbum }
				case .recently_added:
					return albums_selected.sorted { left, right in
						let date_left = AppleLibrary.shared.albumInfo(uAlbum: left.uAlbum)?._date_first_added
						let date_right = AppleLibrary.shared.albumInfo(uAlbum: right.uAlbum)?._date_first_added
						guard date_left != date_right else { return false }
						guard let date_right else { return true }
						guard let date_left else { return false }
						return date_left > date_right
					}
				case .recently_released:
					return albums_selected.sorted { left, right in
						let date_left = AppleLibrary.shared.albumInfo(uAlbum: left.uAlbum)?._date_released
						let date_right = AppleLibrary.shared.albumInfo(uAlbum: right.uAlbum)?._date_released
						guard date_left != date_right else { return false }
						guard let date_right else { return true }
						guard let date_left else { return false }
						return date_left > date_right
					}
			}
		}()
		let indices_selected: [Int] = crate.lrAlbums.indices.filter {
			uAlbums_selected.contains(crate.lrAlbums[$0].uAlbum)
		}
		var albums_sorted = crate.lrAlbums
		indices_selected.indices.forEach { counter in
			let i_selected = indices_selected[counter]
			let album_for_here = albums_selected_sorted[counter]
			albums_sorted[i_selected] = album_for_here
		}
		crate.lrAlbums = albums_sorted
	}
	static func sort_songs(
		_ uSongs_selected: Set<USong>,
		by songOrder: SongOrder
	) {
		guard let album = album_containing_uSongs(uSongs_selected) else { return }
		let uSongs_selected_sorted: [USong] = {
			let uSongs_selected_unsorted = album.uSongs.filter {
				uSongs_selected.contains($0)
			}
			switch songOrder {
				case .reverse: return uSongs_selected_unsorted.reversed()
				case .random: return uSongs_selected_unsorted.in_any_other_order { $0 == $1 }
				case .track:
					return uSongs_selected_unsorted.sorted { left, right in
						let mk_left = AppleLibrary.shared.mkSongs_cache[left]
						let mk_right = AppleLibrary.shared.mkSongs_cache[right]
						if mk_left == nil && mk_right == nil { return false }
						guard let mk_right else { return true }
						guard let mk_left else { return false }
						
						return SongOrder.is_increasing_by_track(same_every_time: false, mk_left, mk_right)
					}
			}
		}()
		let indices_selected: [Int] = album.uSongs.indices.filter {
			uSongs_selected.contains(album.uSongs[$0])
		}
		var uSongs_sorted = album.uSongs
		indices_selected.indices.forEach { counter in
			let i_selected = indices_selected[counter]
			let song_for_here = uSongs_selected_sorted[counter]
			uSongs_sorted[i_selected] = song_for_here
		}
		album.uSongs = uSongs_sorted
	}
	
	private static func album_containing_uSongs(
		_ uSongs: Set<USong>
	) -> LRAlbum? {
		var album_common: LRAlbum? = nil
		for uSong in uSongs {
			guard let album = album_containing_uSong[uSong]?.referencee else { return nil }
			if album_common == nil { album_common = album }
			guard album.uAlbum == album_common?.uAlbum else { return nil }
		}
		return album_common
	}
	
	static func debug_Print() {
		Print()
		Print("crate tree")
		if let the_crate {
			Print("\(the_crate.title): \(the_crate.lrAlbums.count) albums")
			the_crate.lrAlbums.forEach { album in
				Print("  \(album.uAlbum)")
				album.uSongs.forEach { uSong in
					Print("    \(uSong)")
				}
			}
		} else {
			Print("nil crate")
		}
		
		Print("album ID → album:", album_with_uAlbum.count)
		album_with_uAlbum.forEach { (uAlbum, album_ref) in
			var pointee_album = "nil"
			if let album = album_ref.referencee {
				pointee_album = "\(ObjectIdentifier(album))"
			}
			Print("\(uAlbum) → \(pointee_album)")
		}
		
		Print("song IDs:", uSongs_known.count)
		
		Print("song ID → album:", album_containing_uSong.count)
		album_containing_uSong.forEach { (uSong, album_ref) in
			var about_album = "nil"
			if let album = album_ref.referencee {
				about_album = "\(album.uAlbum), \(ObjectIdentifier(album))"
			}
			Print("\(uSong) → \(about_album)")
		}
	}
}
