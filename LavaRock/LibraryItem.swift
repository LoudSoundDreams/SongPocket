// 2021-04-09

import CoreData

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
