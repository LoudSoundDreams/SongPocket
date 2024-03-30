// 2021-08-14

import CoreData

struct AlbumsViewModel {
	let collection: Collection
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var items: [NSManagedObject] {
		didSet { Library.renumber(items) }
	}
}
extension AlbumsViewModel: LibraryViewModel {
	func itemIndex(forRow row: Int) -> Int { return row }
	func rowsForAllItems() -> [Int] {
		return items.indices.map { $0 }
	}
	func row(forItemIndex itemIndex: Int) -> Int { return itemIndex }
	
	// Similar to counterpart in `SongsViewModel`.
	func updatedWithFreshenedData() -> Self {
		return Self(collection: collection, context: context)
	}
	
	func rowIdentifiers() -> [AnyHashable] {
		return items.map { $0.objectID }
	}
}
extension AlbumsViewModel {
	init(
		collection: Collection,
		context: NSManagedObjectContext
	) {
		items = Album.allFetched(sorted: true, inCollection: collection, context: context)
		self.collection = collection
		self.context = context
	}
	
	func albumNonNil(atRow: Int) -> Album {
		return itemNonNil(atRow: atRow) as! Album
	}
}
