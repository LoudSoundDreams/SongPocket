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
	var lrCrate: LRCrate!
	var lrSongs: [LRSong] = []
	
	init(mpid: MPIDAlbum, parent: LRCrate) {
		self.mpid = mpid
		lrCrate = parent
	}
}
final class LRSong {
	let mpid: MPIDSong
	var lrAlbum: LRAlbum!
	
	init(mpid: MPIDSong, parent: LRAlbum) {
		self.mpid = mpid
		lrAlbum = parent
	}
}

@MainActor struct Librarian {
	private(set) static var the_crate: LRCrate?
	
	static func load() {
		// TO DO
	}
	static func save() {
		// TO DO
	}
	
	static func append_lrAlbum(mpid: MPIDAlbum) -> LRAlbum {
		if the_crate == nil {
			the_crate = LRCrate(title: InterfaceText._tilde)
		}
		let the_crate = the_crate!
		
		let lrAlbum_new = LRAlbum(mpid: mpid, parent: the_crate)
		the_crate.lrAlbums.append(lrAlbum_new)
		return lrAlbum_new
	}
	static func append_lrSong(mpid: MPIDSong, in parent: LRAlbum) {
		let lrSong_new = LRSong(mpid: mpid, parent: parent)
		parent.lrSongs.append(lrSong_new)
	}
	
	static func find_lrAlbum(mpid: MPIDAlbum) -> LRAlbum? {
		// TO DO
		return nil
	}
	static func find_lrSong(mpid: MPIDSong) -> LRSong? {
		// TO DO
		return nil
	}
	
	static func debug_print() {
		guard let the_crate else {
			print("nil crate")
			return
		}
		print(the_crate.title)
		the_crate.lrAlbums.forEach { lrAlbum in
			print("  \(lrAlbum.mpid)")
			lrAlbum.lrSongs.forEach { lrSong in
				print("    \(lrSong.mpid)")
			}
		}
	}
}
