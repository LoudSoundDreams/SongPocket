// 2024-09-04

@MainActor final class Library {
	static let shared = Library()
	var lrCrate: LRCrate? = nil
	
	private init() {}
	
	func debug_print() {
		guard let lrCrate else {
			print("nil crate")
			return
		}
		print(lrCrate.title)
		lrCrate.albums.forEach { lrAlbum in
			print(" ", lrAlbum.id_album)
			lrAlbum.songs.forEach { lrSong in
				print("   ", lrSong.id_song)
			}
		}
	}
}

struct LRCrate: Equatable {
	let title: String
	var albums: [LRAlbum]
}
struct LRAlbum: Equatable {
	let id_album: MPIDAlbum
	var songs: [LRSong]
}
struct LRSong: Equatable {
	let id_song: MPIDSong
}
