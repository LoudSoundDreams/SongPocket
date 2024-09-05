// 2024-09-04

@MainActor final class Library {
	static let shared = Library()
	
	private init() {}
}

struct LRCrate: Equatable {
	let title: String
	let albums: [LRAlbum]
}
struct LRAlbum: Equatable {
	let rawID: String
	let songs: [LRSong]
}
struct LRSong: Equatable {
	let rawID: String
}

extension LRCrate: CustomStringConvertible {
	var description: String { "\(title) • albums: \(albums.count)" }
}
extension LRAlbum: CustomStringConvertible {
	var description: String { "\(rawID) • songs: \(songs.count)" }
}
extension LRSong: CustomStringConvertible {
	var description: String { rawID }
}
