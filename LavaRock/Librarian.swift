// 2024-09-04

final class LRCrate {
	let title: String
	var lrAlbums: [LRAlbum] = [] // 2do: Require at least 1 album.
	
	init(title: String) {
		self.title = title
	}
}
final class LRAlbum {
	let mpid: MPIDAlbum
	var lrSongs: [LRSong] = [] // 2do: Require at least 1 song.
	
	init(mpid: MPIDAlbum, songs: [LRSong]) {
		self.mpid = mpid
		self.lrSongs = songs
	}
}
final class LRSong {
	let mpid: MPIDSong
	
	init(mpid: MPIDSong) {
		self.mpid = mpid
	}
}

@MainActor struct Librarian {
	// Browse
	private(set) static var the_crate: LRCrate?
	
	// Search
	static func album_with(mpid: MPIDAlbum) -> LRAlbum? {
		return album_by_id[mpid]?.referencee
	}
	static func song_with(mpid: MPIDSong) -> LRSong? {
		return song_by_id[mpid]?.referencee
	}
	private(set) static var album_from_mpidSong: [MPIDSong: WeakRef<LRAlbum>] = [:]
	private static var album_by_id: [MPIDAlbum: WeakRef<LRAlbum>] = [:]
	private static var song_by_id: [MPIDSong: WeakRef<LRSong>] = [:]
	
	// Register
	static func register_album(_ album_new: LRAlbum) {
		if the_crate == nil {
			the_crate = LRCrate(title: InterfaceText._tilde) // 2do: Do this explicitly, not as a side effect.
		}
		let crate = the_crate!
		
		crate.lrAlbums.append(album_new)
		album_by_id[album_new.mpid] = WeakRef(album_new)
		album_new.lrSongs.forEach { song_new in
			song_by_id[song_new.mpid] = WeakRef(song_new)
			album_from_mpidSong[song_new.mpid] = WeakRef(album_new)
		}
	}
	
	// Deregister
	static func deregister_crate(_ crate_to_remove: LRCrate) {
		the_crate = nil
		
		// 2do: Remove unused dictionary entries.
	}
	
	// Persist
	static func save() {
		guard let the_crate else { return }
		
		Disk.save_crates([the_crate])
	}
	static func load() {
		guard let crate_loaded = Disk.load_crates().first else { return }
		
		crate_loaded.lrAlbums.forEach { album_loaded in
			register_album(album_loaded)
		}
	}
	
	static func promote_albums(_ mpids_selected: Set<MPIDAlbum>) {
		guard let parent = the_crate else { return }
		let rs_to_promote = parent.lrAlbums.indices(where: { album in
			mpids_selected.contains(album.mpid)
		})
		guard let front: Int = rs_to_promote.ranges.first?.first else { return }
		
		let target: Int = (rs_to_promote.ranges.count == 1)
		? max(front-1, 0)
		: front
		var albums_reordered = parent.lrAlbums
		albums_reordered.moveSubranges(rs_to_promote, to: target)
		parent.lrAlbums = albums_reordered
	}
	static func promote_songs(_ mpids_selected: Set<MPIDSong>) {
		// Verify that the selected songs are in the same album. Find that album.
		var parent: LRAlbum? = nil
		for mpid in mpids_selected {
			guard let this_parent = album_from_mpidSong[mpid]?.referencee else { return }
			if parent == nil { parent = this_parent }
			guard parent?.mpid == this_parent.mpid else { return }
		}
		guard let parent else { return }
		
		// Find the index of the frontmost selected song.
		let rs_to_promote = parent.lrSongs.indices(where: { song in
			mpids_selected.contains(song.mpid)
		})
		guard let front: Int = rs_to_promote.ranges.first?.first else { return }
		
		let target: Int = (rs_to_promote.ranges.count == 1) // If contiguous …
		? max(front-1, 0) // … 1 step toward beginning, but stay in bounds.
		: front // … make contiguous starting at front.
		var songs_reordered = parent.lrSongs
		songs_reordered.moveSubranges(rs_to_promote, to: target)
		parent.lrSongs = songs_reordered
	}
	
	static func debug_Print() {
		Print()
		Print("crate tree")
		if let the_crate {
			Print(the_crate.title)
			the_crate.lrAlbums.forEach { album in
				Print("  \(album.mpid)")
				album.lrSongs.forEach { song in
					Print("    \(song.mpid)")
				}
			}
		} else {
			Print("nil crate")
		}
		
		Print()
		Print("album dict")
		album_by_id.forEach { (mpidAlbum, album_ref) in
			var pointee_album = "nil"
			if let album = album_ref.referencee {
				pointee_album = "\(ObjectIdentifier(album))"
			}
			Print("\(mpidAlbum) → \(pointee_album)")
		}
		
		Print()
		Print("song dict")
		song_by_id.forEach { (mpidSong, song_ref) in
			var pointee_song = "nil"
			if let song = song_ref.referencee {
				pointee_song = "\(ObjectIdentifier(song))"
			}
			Print("\(mpidSong) → \(pointee_song)")
		}
		
		Print()
		Print("song ID → album")
		album_from_mpidSong.forEach { (mpidSong, album_ref) in
			var about_album = "nil"
			if let album = album_ref.referencee {
				about_album = "\(album.mpid), \(ObjectIdentifier(album))"
			}
			Print("\(mpidSong) → \(about_album)")
		}
	}
}
