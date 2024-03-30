// 2021-08-14

import CoreData

struct SongsViewModel {
	static let prerowCount = 1
	let album: Album
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var items: [NSManagedObject] {
		didSet { Library.renumber(items) }
	}
}
extension SongsViewModel: LibraryViewModel {
	func itemIndex(forRow row: Int) -> Int {
		return row - Self.prerowCount
	}
	func rowsForAllItems() -> [Int] {
		return items.indices.map {
			Self.prerowCount + $0
		}
	}
	func row(forItemIndex itemIndex: Int) -> Int {
		return Self.prerowCount + itemIndex
	}
	
	// Similar to counterpart in `AlbumsViewModel`.
	func updatedWithFreshenedData() -> Self {
		return Self(album: album, context: context)
	}
	
	func rowIdentifiers() -> [AnyHashable] {
		let itemRowIDs = items.map {
			AnyHashable($0.objectID)
		}
		return [42] + itemRowIDs
	}
}
extension SongsViewModel {
	init(
		album: Album,
		context: NSManagedObjectContext
	) {
		items = Song.allFetched(sorted: true, inAlbum: album, context: context)
		self.album = album
		self.context = context
	}
}
