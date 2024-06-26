// 2020-12-17

import CoreData

extension Collection {
	// Similar to `Album.fetchRequest_sorted`.
	static func fetchRequest_sorted() -> NSFetchRequest<Collection> {
		let result = fetchRequest()
		result.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		return result
	}
	
	// Similar to `Album.songs`.
	final func albums(sorted: Bool) -> [Album] {
		guard let contents else { return [] }
		
		let unsorted = contents.map { $0 as! Album }
		guard sorted else { return unsorted }
		
		return unsorted.sorted { $0.index < $1.index }
	}
}
