// 2024-09-04

@MainActor struct LRLibrary {
	static var lrCrate: LRCrate? = nil
	
	static func debug_print() {
		guard let lrCrate else {
			print("nil crate")
			return
		}
		print(lrCrate.title)
		lrCrate.lrAlbums.forEach { lrAlbum in
			print("  \(lrAlbum.mpidAlbum)")
			lrAlbum.lrSongs.forEach { lrSong in
				print("    \(lrSong.mpidSong)")
			}
		}
	}
}

struct LRCrate: Equatable {
	let title: String
	var lrAlbums: [LRAlbum]
}
struct LRAlbum: Equatable {
	let mpidAlbum: MPIDAlbum
	var lrSongs: [LRSong]
}
struct LRSong: Equatable {
	let mpidSong: MPIDSong
}
