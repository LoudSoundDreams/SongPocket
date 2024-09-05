// 2024-09-04

@MainActor final class Library {
	static let shared = Library()
	
	private init() {}
}

struct LRCrate: Equatable {
	let title: String
	let albums: [LRAlbum]
}; extension LRCrate: CustomStringConvertible {
	var description: String { "\(title) • albums: \(albums.count)" }
}
struct LRAlbum: Equatable {
	let rawID: String
	let songs: [LRSong]
}; extension LRAlbum: CustomStringConvertible {
	var description: String { "\(rawID) • songs: \(songs.count)" }
}
struct LRSong: Equatable {
	let rawID: String
}; extension LRSong: CustomStringConvertible {
	var description: String { rawID }
}
