// 2021-08-14

import CoreData

struct CollectionsViewModel {
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var items: [NSManagedObject] {
		didSet { Fn.renumber(items) }
	}
}
extension CollectionsViewModel: LibraryViewModel {
	func itemIndex(forRow row: Int) -> Int { return row }
	func rowsForAllItems() -> [Int] {
		return items.indices.map { $0 }
	}
	func row(forItemIndex itemIndex: Int) -> Int { return itemIndex }
	
	func updatedWithFreshenedData() -> Self {
		return Self(context: context)
	}
	func rowIdentifiers() -> [AnyHashable] {
		return items.map { $0.objectID }
	}
}
extension CollectionsViewModel {
	init(context: NSManagedObjectContext) {
		items = Collection.allFetched(sorted: true, context: context)
		self.context = context
	}
	
	func collectionNonNil(atRow: Int) -> Collection {
		return itemNonNil(atRow: atRow) as! Collection
	}
	
	// MARK: - “Move” sheet
	
	static let indexOfNewCollection = 0
	func updatedAfterCreating() -> Self {
		let newCollection = Collection(context: context)
		newCollection.title = LRString.tilde
		
		var newItems = items
		newItems.insert(newCollection, at: Self.indexOfNewCollection)
		
		var twin = self
		twin.items = newItems
		return twin
	}
	func updatedAfterDeletingNewCollection() -> Self {
		let newItems = itemsAfterDeletingNewCollection()
		
		var twin = self
		twin.items = newItems
		return twin
	}
	private func itemsAfterDeletingNewCollection() -> [NSManagedObject] {
		let oldItems = items
		guard
			let collection = oldItems[Self.indexOfNewCollection] as? Collection,
			collection.isEmpty()
		else {
			return oldItems
		}
		
		context.delete(collection)
		
		var newItems = items
		newItems.remove(at: Self.indexOfNewCollection)
		return newItems
	}
}
