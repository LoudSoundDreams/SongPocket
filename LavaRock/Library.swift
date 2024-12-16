// 2024-09-04

@MainActor final class Library {
	static let shared = Library()
	var lrCrate: LRCrate? = nil
	
	private init() {}
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
