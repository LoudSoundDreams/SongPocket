// 2021-08-14

import CoreData

struct AlbumsViewModel {
	// `LibraryViewModel`
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
		return Self()
	}
	
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
	
	func albumNonNil(atRow: Int) -> Album {
		return itemNonNil(atRow: atRow) as! Album
	}
}
