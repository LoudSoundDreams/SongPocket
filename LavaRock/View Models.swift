// 2021-08-12

import CoreData

@MainActor struct AlbumsViewModel {
	var albums: [Album] = Collection.allFetched(sorted: false, context: Database.viewContext).first?.albums(sorted: true) ?? [] {
		didSet { Database.renumber(albums) }
	}
	func withRefreshedData() -> Self { return Self() }
	func rowIdentifiers() -> [AnyHashable] {
		return albums.map { $0.objectID }
	}
}

struct SongsViewModel {
	static let prerowCount = 1
	var songs: [Song] { didSet { Database.renumber(songs) } }
	func withRefreshedData() -> Self {
		// Get the `Album` from the first non-deleted `Song`.
		guard let album = songs.first(where: { nil != $0.container })?.container else {
			return Self(songs: [])
		}
		return Self(album: album)
	}
	func rowIdentifiers() -> [AnyHashable] {
		let itemRowIDs = songs.map { AnyHashable($0.objectID) }
		return [42] + itemRowIDs
	}
}
extension SongsViewModel {
	init(album: Album) { songs = album.songs(sorted: true) }
}
