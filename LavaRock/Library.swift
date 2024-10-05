// 2024-09-04

struct LRCrate: Equatable {
	let title: String
	var albums: [LRAlbum]
}
struct LRAlbum: Equatable {
	let mpidAlbum: MPID
	var songs: [LRSong]
}
struct LRSong: Equatable {
	let mpidSong: MPID
}

@MainActor final class Library {
	static let shared = Library()
	var lrCrate: LRCrate? = nil
	
	private init() {}
}

extension LRCrate: CustomStringConvertible {
	var description: String { "\(title) → albums: \(albums.count)" }
}
extension LRAlbum: CustomStringConvertible {
	var description: String { "\(mpidAlbum) → songs: \(songs.count)" }
}
extension LRSong: CustomStringConvertible {
	var description: String { "\(mpidSong)" }
}
