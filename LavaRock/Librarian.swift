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
	var lrSongs: [LRSong] = []
	init(uAlbum: UAlbum, songs: [LRSong]) {
		self.uAlbum = uAlbum
		self.lrSongs = songs
	}
}
final class LRSong { // 2do: Needless! Delete.
	let uSong: USong
	init(uSong: USong) {
		self.uSong = uSong
	}
}

@MainActor struct Librarian {
	static let signposter = OSSignposter(subsystem: "librarian", category: .pointsOfInterest)
	
	// Browse
	private(set) static var the_crate: LRCrate?
	
	// Search
	private(set) static var album_with_uAlbum: [UAlbum: WeakRef<LRAlbum>] = [:]
	private(set) static var song_with_uSong: [USong: WeakRef<LRSong>] = [:]
	private(set) static var album_containing_uSong: [USong: WeakRef<LRAlbum>] = [:]
	
	// Register
	static func reset_the_crate() {
		the_crate = LRCrate(title: InterfaceText._tilde)
	}
	static func register_album(
		_ album_new: LRAlbum
	) {
		album_with_uAlbum[album_new.uAlbum] = WeakRef(album_new)
		album_new.lrSongs.forEach { song_new in
			register_song(song_new, with: album_new)
		}
	}
	static func register_song(
		_ song_new: LRSong,
		with album_target: LRAlbum
	) {
		song_with_uSong[song_new.uSong] = WeakRef(song_new)
		album_containing_uSong[song_new.uSong] = WeakRef(album_target)
	}
	
	// Deregister
	static func deregister_uAlbum(_ uAlbum: UAlbum) {
		let album = album_with_uAlbum[uAlbum]?.referencee
		album_with_uAlbum[uAlbum] = nil
		album?.lrSongs.forEach { song in
			deregister_uSong(song.uSong)
		}
	}
	static func deregister_uSong(_ uSong: USong) {
		song_with_uSong[uSong] = nil
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
		let rs_to_promote = album.lrSongs.indices(where: { song in
			uSongs_selected.contains(song.uSong)
		})
		let target: Int? = (
			to_limit
			? 0
			: target_promoting(rs_to_promote)
		)
		guard let target else { return }
		album.lrSongs.moveSubranges(rs_to_promote, to: target)
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
		let rs_to_demote = album.lrSongs.indices(where: { song in
			uSongs_selected.contains(song.uSong)
		})
		let target: Int? = (
			to_limit
			? album.lrSongs.count-1
			: target_demoting(
				rs_to_demote,
				index_max: album.lrSongs.count-1)
		)
		guard let target else { return }
		album.lrSongs.moveSubranges(rs_to_demote, to: target+1)
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
				case .random: break
				case .recently_added:
					break
				case .recently_released:
					break
			}
			return albums_selected // 2do
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
		let songs_selected_sorted: [LRSong] = {
			let songs_selected = album.lrSongs.filter {
				uSongs_selected.contains($0.uSong)
			}
			switch songOrder {
				case .reverse: return songs_selected.reversed()
				case .random: break
				case .track:
					break
			}
			return songs_selected // 2do
		}()
		let indices_selected: [Int] = album.lrSongs.indices.filter {
			uSongs_selected.contains(album.lrSongs[$0].uSong)
		}
		var songs_sorted = album.lrSongs
		indices_selected.indices.forEach { counter in
			let i_selected = indices_selected[counter]
			let song_for_here = songs_selected_sorted[counter]
			songs_sorted[i_selected] = song_for_here
		}
		album.lrSongs = songs_sorted
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
				album.lrSongs.forEach { song in
					Print("    \(song.uSong)")
				}
			}
		} else {
			Print("nil crate")
		}
		
		Print("album dict:", album_with_uAlbum.count)
		album_with_uAlbum.forEach { (uAlbum, album_ref) in
			var pointee_album = "nil"
			if let album = album_ref.referencee {
				pointee_album = "\(ObjectIdentifier(album))"
			}
			Print("\(uAlbum) → \(pointee_album)")
		}
		
		Print("song dict:", song_with_uSong.count)
		song_with_uSong.forEach { (uSong, song_ref) in
			var pointee_song = "nil"
			if let song = song_ref.referencee {
				pointee_song = "\(ObjectIdentifier(song))"
			}
			Print("\(uSong) → \(pointee_song)")
		}
		
		Print("song ID → album", album_containing_uSong.count)
		album_containing_uSong.forEach { (uSong, album_ref) in
			var about_album = "nil"
			if let album = album_ref.referencee {
				about_album = "\(album.uAlbum), \(ObjectIdentifier(album))"
			}
			Print("\(uSong) → \(about_album)")
		}
	}
}
