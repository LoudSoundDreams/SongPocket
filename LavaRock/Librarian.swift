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
	
	init(mpid: MPIDAlbum) {
		self.mpid = mpid
	}
}
final class LRSong {
	let mpid: MPIDSong
	weak var lrAlbum: LRAlbum!
	
	init(mpid: MPIDSong, parent: LRAlbum) {
		self.mpid = mpid
		lrAlbum = parent
	}
}

@MainActor struct Librarian {
	// Tree
	private(set) static var the_crate: LRCrate?
	
	// Dictionaries
	static func album_with(mpid: MPIDAlbum) -> LRAlbum? {
		return dict_albums[mpid]?.referencee
	}
	static func song_with(mpid: MPIDSong) -> LRSong? {
		return dict_songs[mpid]?.referencee
	}
	private static var dict_albums: [MPIDAlbum: WeakRef<LRAlbum>] = [:]
	private static var dict_songs: [MPIDSong: WeakRef<LRSong>] = [:]
	
	static func register_album(mpid: MPIDAlbum) -> LRAlbum {
		if the_crate == nil {
			the_crate = LRCrate(title: InterfaceText._tilde) // TO DO: Do this explicitly, not as a side effect.
		}
		let crate = the_crate!
		
		let album_new = LRAlbum(mpid: mpid)
		dict_albums[mpid] = WeakRef(album_new)
		crate.lrAlbums.append(album_new)
		return album_new
	}
	static func register_song(mpid: MPIDSong, in parent: LRAlbum) {
		let song_new = LRSong(mpid: mpid, parent: parent)
		dict_songs[mpid] = WeakRef(song_new)
		parent.lrSongs.append(song_new)
	}
	
	static func deregister_crate(_ crate_to_remove: LRCrate) {
		// TO DO
	}
	
	// Persistence
	static func save() {
		guard let the_crate else { return }
		
		Disk.save_crates([the_crate])
	}
	static func load() {
		// TO DO
	}
	
	static func debug_Print() {
		Print()
		guard let the_crate else {
			Print("nil crate")
			return
		}
		Print("crate tree")
		Print(the_crate.title)
		the_crate.lrAlbums.forEach { album in
			Print("  \(album.mpid)")
			album.lrSongs.forEach { song in
				Print("    \(song.mpid), in \(song.lrAlbum.mpid)")
			}
		}
		
		Print()
		Print("album dict")
		dict_albums.forEach { (mpidAlbum, album_ref) in
			var value_description = "nil"
			if let album = album_ref.referencee {
				value_description = "\(ObjectIdentifier(album))"
			}
			Print("\(mpidAlbum) → \(value_description)")
		}
		
		Print()
		Print("song dict")
		dict_songs.forEach { (mpidSong, song_ref) in
			var value_description = "nil"
			if let song = song_ref.referencee {
				value_description = "\(ObjectIdentifier(song))"
			}
			Print("\(mpidSong) → \(value_description)")
		}
	}
}
