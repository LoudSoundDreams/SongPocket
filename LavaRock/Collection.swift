// 2020-12-17

import CoreData

extension Collection {
	convenience init(
		afterAllOtherCount existingCount: Int,
		title: String,
		context: NSManagedObjectContext
	) {
		self.init(context: context)
		self.title = title
		index = Int64(existingCount)
	}
	
	// MARK: - All instances
	
	// Similar to `Album.allFetched`.
	static func allFetched(
		sorted: Bool,
		context: NSManagedObjectContext
	) -> [Collection] {
		let fetchRequest = fetchRequest()
		if sorted {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return context.objectsFetched(for: fetchRequest)
	}
	
	// MARK: - Albums
	
	// Similar to `Album.songs`.
	final func albums(sorted: Bool) -> [Album] {
		guard let contents else { return [] }
		
		let unsorted = contents.map { $0 as! Album }
		guard sorted else { return unsorted }
		
		return unsorted.sorted { $0.index < $1.index }
	}
}
