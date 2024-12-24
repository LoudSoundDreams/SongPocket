// 2024-09-04

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
final class LRSong {
	let uSong: USong
	init(uSong: USong) {
		self.uSong = uSong
	}
}

@MainActor struct Librarian {
	// Browse
	private(set) static var the_crate: LRCrate?
	
	// Search
	private(set) static var album_with_uAlbum: [UAlbum: WeakRef<LRAlbum>] = [:]
	private(set) static var song_with_uSong: [USong: WeakRef<LRSong>] = [:]
	private(set) static var album_containing_uSong: [USong: WeakRef<LRAlbum>] = [:]
	
	// Insert
	static func insert_album(_ album_new: LRAlbum) {
		if the_crate == nil {
			the_crate = LRCrate(title: InterfaceText._tilde)
		}
		let crate = the_crate!
		
		crate.lrAlbums.insert(album_new, at: 0)
		album_with_uAlbum[album_new.uAlbum] = WeakRef(album_new)
		album_new.lrSongs.forEach { song_new in
			song_with_uSong[song_new.uSong] = WeakRef(song_new)
			album_containing_uSong[song_new.uSong] = WeakRef(album_new)
		}
	}
	
	// Persist
	static func save() {
		guard let the_crate else { return }
		
		Disk.save_crates([the_crate])
	}
	static func load() {
		guard let crate_loaded = Disk.load_crates().first else { return }
		
		crate_loaded.lrAlbums.reversed().forEach { album_loaded in
			insert_album(album_loaded)
		}
	}
	
	// Edit
	static func promote_albums(_ uAlbums_selected: Set<UAlbum>) {
		guard let parent = the_crate else { return }
		let rs_to_promote = parent.lrAlbums.indices(where: { album in
			uAlbums_selected.contains(album.uAlbum)
		})
		guard let front: Int = rs_to_promote.ranges.first?.first else { return }
		
		let target: Int = (rs_to_promote.ranges.count == 1)
		? max(front-1, 0)
		: front
		var albums_reordered = parent.lrAlbums
		albums_reordered.moveSubranges(rs_to_promote, to: target)
		parent.lrAlbums = albums_reordered
	}
	static func promote_songs(_ uSongs_selected: Set<USong>) {
		// Verify that the selected songs are in the same album. Find that album.
		var parent: LRAlbum? = nil
		for uSong in uSongs_selected {
			guard let this_parent = album_containing_uSong[uSong]?.referencee else { return }
			if parent == nil { parent = this_parent }
			guard parent?.uAlbum == this_parent.uAlbum else { return }
		}
		guard let parent else { return }
		
		// Find the index of the frontmost selected song.
		let rs_to_promote = parent.lrSongs.indices(where: { song in
			uSongs_selected.contains(song.uSong)
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
				Print("  \(album.uAlbum)")
				album.lrSongs.forEach { song in
					Print("    \(song.uSong)")
				}
			}
		} else {
			Print("nil crate")
		}
		
		Print()
		Print("album dict")
		album_with_uAlbum.forEach { (uAlbum, album_ref) in
			var pointee_album = "nil"
			if let album = album_ref.referencee {
				pointee_album = "\(ObjectIdentifier(album))"
			}
			Print("\(uAlbum) → \(pointee_album)")
		}
		
		Print()
		Print("song dict")
		song_with_uSong.forEach { (uSong, song_ref) in
			var pointee_song = "nil"
			if let song = song_ref.referencee {
				pointee_song = "\(ObjectIdentifier(song))"
			}
			Print("\(uSong) → \(pointee_song)")
		}
		
		Print()
		Print("song ID → album")
		album_containing_uSong.forEach { (uSong, album_ref) in
			var about_album = "nil"
			if let album = album_ref.referencee {
				about_album = "\(album.uAlbum), \(ObjectIdentifier(album))"
			}
			Print("\(uSong) → \(about_album)")
		}
	}
}
