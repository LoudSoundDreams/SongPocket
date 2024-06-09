// 2021-08-12

import CoreData

protocol LibraryViewModel {
	func isEmpty() -> Bool // TO DO: Delete
	func itemIndex(forRow row: Int) -> Int // TO DO: Delete
	func withRefreshedData() -> Self
	func rowIdentifiers() -> [AnyHashable]
}

struct ExpandableViewModel {
	var albums: [Album] = Collection.allFetched(sorted: false, context: Database.viewContext).first?.albums(sorted: true) ?? [] {
		didSet { Database.renumber(albums) }
	}
	var expandedIndex: Int? = nil
	
	func itemForIndexPath(_ indexPath: IndexPath) -> Item {
		guard let expandedIndex, indexPath.row > expandedIndex else {
			// Before any song rows
			return .album(albums[indexPath.row])
		}
		let skippedAlbumCount = expandedIndex + 1
		let rowIndexAfterSkippedAlbums = indexPath.row - skippedAlbumCount
		let songs = albums[expandedIndex].songs(sorted: true)
		let isSongRow = rowIndexAfterSkippedAlbums < songs.count
		guard !isSongRow else {
			return Item.song(songs[rowIndexAfterSkippedAlbums])
		}
		let albumIndex = rowIndexAfterSkippedAlbums - songs.count
		return Item.album(albums[albumIndex])
	}
	enum Item { case album(Album), song(Song) }
	
	mutating func collapseAllThenExpand(_ album: Album) {
		collapseAll()
		expandedIndex = albums.firstIndex(where: { album.objectID == $0.objectID })
	}
	mutating func collapseAll() {
		expandedIndex = nil
	}
}

struct AlbumsViewModel {
	var albums: [Album] = Collection.allFetched(sorted: false, context: Database.viewContext).first?.albums(sorted: true) ?? [] {
		didSet { Database.renumber(albums) }
	}
}
extension AlbumsViewModel: LibraryViewModel {
	func isEmpty() -> Bool { return albums.isEmpty }
	func itemIndex(forRow row: Int) -> Int { return row }
	func withRefreshedData() -> Self { return Self() }
	func rowIdentifiers() -> [AnyHashable] {
		return albums.map { $0.objectID }
	}
}

struct SongsViewModel {
	static let prerowCount = 1
	var songs: [Song] { didSet { Database.renumber(songs) } }
}
extension SongsViewModel: LibraryViewModel {
	func isEmpty() -> Bool { return songs.isEmpty }
	func itemIndex(forRow row: Int) -> Int { return row - Self.prerowCount }
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
