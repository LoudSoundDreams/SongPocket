// 2024-09-04

struct LRCrate: Equatable {
	let title: String
	var lrAlbums: [LRAlbum]
}
struct LRAlbum: Equatable {
	let mpid: MPIDAlbum
	var lrSongs: [LRSong]
}
struct LRSong: Equatable {
	let mpid: MPIDSong
	let album_mpid: MPIDAlbum
}

@MainActor struct Librarian {
	private(set) static var lrCrate: LRCrate? = nil
	
	static func load() {
		// TO DO
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
		guard let lrCrate else {
			print("nil crate")
			return
		}
		print(lrCrate.title)
		lrCrate.lrAlbums.forEach { lrAlbum in
			print("  \(lrAlbum.mpid)")
			lrAlbum.lrSongs.forEach { lrSong in
				print("    \(lrSong.mpid)")
			}
		}
	}
}
