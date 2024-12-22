// 2024-09-04

final class LRCrate {
	let title: String
	var lrAlbums: [LRAlbum] = []
	
	init(title: String) {
		self.title = title
	}
}
final class LRAlbum {
	let mpid: MPIDAlbum
	weak var lrCrate: LRCrate!
	var lrSongs: [LRSong] = []
	
	init(mpid: MPIDAlbum, parent: LRCrate) {
		self.mpid = mpid
		lrCrate = parent
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
	
	static func append_album(mpid: MPIDAlbum) -> LRAlbum {
		if the_crate == nil {
			the_crate = LRCrate(title: InterfaceText._tilde) // TO DO: Do this explicitly, not as a side effect.
		}
		let crate = the_crate!
		
		let album_new = LRAlbum(mpid: mpid, parent: crate)
		dict_albums[mpid] = WeakRef(album_new)
		crate.lrAlbums.append(album_new)
		return album_new
	}
	static func append_song(mpid: MPIDSong, in parent: LRAlbum) {
		let song_new = LRSong(mpid: mpid, parent: parent)
		dict_songs[mpid] = WeakRef(song_new)
		parent.lrSongs.append(song_new)
	}
	
	static func remove_crate(_ crate_to_remove: LRCrate) {
		// TO DO
	}
	
	// Persistence
	static func save() {
		// TO DO
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
			Print("  \(album.mpid) in \(album.lrCrate.title)")
			album.lrSongs.forEach { song in
				Print("    \(song.mpid) in \(song.lrAlbum.mpid)")
			}
		}
		
		Print()
		Print("album dict")
		dict_albums.forEach { (mpidAlbum, album_ref) in
			var value_description = "nil"
			if let album = album_ref.referencee {
				value_description = "\(ObjectIdentifier(album).debugDescription), \(album.mpid)"
			}
			Print("\(mpidAlbum) → \(value_description)")
		}
		
		Print()
		Print("song dict")
		dict_songs.forEach { (mpidSong, song_ref) in
			var value_description = "nil"
			if let song = song_ref.referencee {
				value_description = "\(ObjectIdentifier(song).debugDescription), \(song.mpid)"
			}
			Print("\(mpidSong) → \(value_description)")
		}
	}
}
