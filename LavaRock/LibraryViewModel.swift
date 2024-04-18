// 2021-08-12

import CoreData

protocol LibraryViewModel {
	// You must add a `didSet` that calls `Library.renumber(items)`.
	var items: [NSManagedObject] { get set }
	
	func itemIndex(forRow row: Int) -> Int
	func rowsForAllItems() -> [Int]
	
	func withRefreshedData() -> Self
	func rowIdentifiers() -> [AnyHashable]
}
extension LibraryViewModel {
	func itemNonNil(atRow: Int) -> NSManagedObject {
		let itemIndex = itemIndex(forRow: atRow)
		return items[itemIndex]
	}
}

struct AlbumsViewModel {
	// `LibraryViewModel`
	var items: [NSManagedObject] { didSet { Library.renumber(items) } }
}
extension AlbumsViewModel: LibraryViewModel {
	func itemIndex(forRow row: Int) -> Int { return row }
	func rowsForAllItems() -> [Int] {
		return items.indices.map { $0 }
	}
	
	func withRefreshedData() -> Self { return Self() }
	func rowIdentifiers() -> [AnyHashable] {
		return items.map { $0.objectID }
	}
}
extension AlbumsViewModel {
	init() {
		if
			let collection = Collection.allFetched(sorted: false, context: Database.viewContext).first,
			let context = collection.managedObjectContext
		{
			items = Album.allFetched(sorted: true, inCollection: collection, context: context)
		} else {
			// We deleted `collection`
			items = []
		}
	}
}

struct SongsViewModel {
	static let prerowCount = 1
	let album: Album
	
	// `LibraryViewModel`
	var items: [NSManagedObject] { didSet { Library.renumber(items) } }
}
extension SongsViewModel: LibraryViewModel {
	func itemIndex(forRow row: Int) -> Int { return row - Self.prerowCount }
	func rowsForAllItems() -> [Int] {
		return items.indices.map { Self.prerowCount + $0 }
	}
	
	func withRefreshedData() -> Self { return Self(album: album) }
	func rowIdentifiers() -> [AnyHashable] {
		let itemRowIDs = items.map {
			AnyHashable($0.objectID)
		}
		return [42] + itemRowIDs
	}
}
extension SongsViewModel {
	init(album: Album) {
		if let context = album.managedObjectContext {
			items = Song.allFetched(sorted: true, inAlbum: album, context: context)
		} else {
			items = []
		}
		self.album = album
	}
}
