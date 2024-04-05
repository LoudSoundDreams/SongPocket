// 2021-08-12

import CoreData

protocol LibraryViewModel {
	// You must add a `didSet` that calls `Fn.renumber(items)`.
	var items: [NSManagedObject] { get set }
	
	func itemIndex(forRow row: Int) -> Int
	func rowsForAllItems() -> [Int]
	func row(forItemIndex itemIndex: Int) -> Int
	
	func updatedWithFreshenedData() -> Self
	func rowIdentifiers() -> [AnyHashable]
}
extension LibraryViewModel {
	func itemNonNil(atRow: Int) -> NSManagedObject {
		let itemIndex = itemIndex(forRow: atRow)
		return items[itemIndex]
	}
}
