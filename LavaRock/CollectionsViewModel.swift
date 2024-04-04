// 2021-08-14

import CoreData

struct CollectionsViewModel {
	let context: NSManagedObjectContext = Database.viewContext
	
	// `LibraryViewModel`
	var items: [NSManagedObject] {
		didSet { Library.renumber(items) }
	}
}
extension CollectionsViewModel: LibraryViewModel {
	func itemIndex(forRow row: Int) -> Int { return row }
	func rowsForAllItems() -> [Int] {
		return items.indices.map { $0 }
	}
	func row(forItemIndex itemIndex: Int) -> Int { return itemIndex }
	
	func updatedWithFreshenedData() -> Self {
		return Self()
	}
	func rowIdentifiers() -> [AnyHashable] {
		return items.map { $0.objectID }
	}
}
extension CollectionsViewModel {
	init() {
		items = Collection.allFetched(sorted: true, context: context)
	}
	
	func collectionNonNil(atRow: Int) -> Collection {
		return itemNonNil(atRow: atRow) as! Collection
	}
}
