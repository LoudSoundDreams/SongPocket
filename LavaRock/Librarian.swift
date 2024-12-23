// 2024-09-04

final class LRCrate {
	let title: String
	var lrAlbums: [LRAlbum] = [] // TO DO: Require at least 1 album.
	
	init(title: String) {
		self.title = title
	}
}
final class LRAlbum {
	let mpid: MPIDAlbum
	var lrSongs: [LRSong] = [] // TO DO: Require at least 1 song.
	
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
		return dict_albums[mpid]?.referencee
	}
	static func song_with(mpid: MPIDSong) -> LRSong? {
		return dict_songs[mpid]?.referencee
	}
	private(set) static var album_from_mpidSong: [MPIDSong: WeakRef<LRAlbum>] = [:]
	private static var dict_albums: [MPIDAlbum: WeakRef<LRAlbum>] = [:] // TO DO: album_by_mpidAlbum
	private static var dict_songs: [MPIDSong: WeakRef<LRSong>] = [:] // TO DO: song_by_mpid
	
	// Register
	static func register_album(_ album_new: LRAlbum) {
		if the_crate == nil {
			the_crate = LRCrate(title: InterfaceText._tilde) // TO DO: Do this explicitly, not as a side effect.
		}
		let crate = the_crate!
		
		crate.lrAlbums.append(album_new)
		dict_albums[album_new.mpid] = WeakRef(album_new)
		album_new.lrSongs.forEach { song_new in
			dict_songs[song_new.mpid] = WeakRef(song_new)
			album_from_mpidSong[song_new.mpid] = WeakRef(album_new)
		}
	}
	
	// Deregister
	static func deregister_crate(_ crate_to_remove: LRCrate) {
		the_crate = nil
		
		// TO DO: Remove unused dictionary entries.
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
		dict_albums.forEach { (mpidAlbum, album_ref) in
			var pointee_album = "nil"
			if let album = album_ref.referencee {
				pointee_album = "\(ObjectIdentifier(album))"
			}
			Print("\(mpidAlbum) → \(pointee_album)")
		}
		
		Print()
		Print("song dict")
		dict_songs.forEach { (mpidSong, song_ref) in
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
