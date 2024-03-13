//
//  CollectionsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import CoreData

struct CollectionsViewModel {
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var group: LibraryGroup?
}
extension CollectionsViewModel: LibraryViewModel {
	func itemIndex(forRow row: Int) -> Int { return row }
	func rowsForAllItems() -> [Int] {
		guard !isEmpty() else {
			return []
		}
		return libraryGroup().items.indices.map { $0 }
	}
	func row(forItemIndex itemIndex: Int) -> Int { return itemIndex }
	
	func updatedWithFreshenedData() -> Self {
		return Self(context: context)
	}
	func rowIdentifiers() -> [AnyHashable] {
		return group!.items.map { $0.objectID }
	}
}
extension CollectionsViewModel {
	init(context: NSManagedObjectContext) {
		self.context = context
		group = CollectionsGroup(context: context)
	}
	
	func collectionNonNil(atRow: Int) -> Collection {
		return itemNonNil(atRow: atRow) as! Collection
	}
	
	private func updatedWithItemsInOnlyGroup(_ newItems: [NSManagedObject]) -> Self {
		var twin = self
		twin.group!.items = newItems
		return twin
	}
	
	// MARK: - “Move” sheet
	
	static let indexOfNewCollection = 0
	
	func updatedAfterCreating() -> Self {
		let newCollection = Collection(context: context)
		newCollection.title = LRString.tilde
		// When we call `setViewModelAndMoveAndDeselectRowsAndShouldContinue`, the property observer will set each `Collection.index` for us.
		
		var newItems = libraryGroup().items
		newItems.insert(newCollection, at: Self.indexOfNewCollection)
		
		return updatedWithItemsInOnlyGroup(newItems)
	}
	
	func updatedAfterDeletingNewCollection() -> Self {
		let newItems = itemsAfterDeletingNewCollection()
		
		return updatedWithItemsInOnlyGroup(newItems)
	}
	private func itemsAfterDeletingNewCollection() -> [NSManagedObject] {
		let oldItems = libraryGroup().items
		guard
			let collection = oldItems[Self.indexOfNewCollection] as? Collection,
			collection.isEmpty()
		else {
			return oldItems
		}
		
		context.delete(collection)
		
		var newItems = libraryGroup().items
		newItems.remove(at: Self.indexOfNewCollection)
		return newItems
	}
}
