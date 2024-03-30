// 2021-04-09

import CoreData

enum Library {
	static func renumber(_ items: [NSManagedObject]) { // Replace with `LibraryItem`
		items.enumerated().forEach { (currentIndex, item) in
			item.setValue(Int64(currentIndex), forKey: "index")
		}
	}
}

protocol LibraryContainer: NSManagedObject {
	var contents: NSSet? { get }
}
extension LibraryContainer {
	func isEmpty() -> Bool {
		return contents == nil || contents?.count == 0
	}
}

protocol LibraryItem: NSManagedObject {
	var index: Int64 { get set }
	
	@MainActor func containsPlayhead() -> Bool
}
