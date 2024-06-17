// 2020-07-10

import CoreData

extension Album {
	convenience init?(atEndOf collection: Collection, albumID: AlbumID) {
		guard let context = collection.managedObjectContext else { return nil }
		self.init(context: context)
		index = Int64(collection.contents?.count ?? 0)
		container = collection
		albumPersistentID = albumID
	}
	
	// Use `init(atEndOf:albumID:)` if possible. It’s faster.
	convenience init?(atBeginningOf collection: Collection, albumID: AlbumID) {
		guard let context = collection.managedObjectContext else { return nil }
		
		collection.albums(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		index = 0
		container = collection
		albumPersistentID = albumID
	}
	
	// MARK: - Fetching
	
	// Similar to `Collection.allFetched`.
	static func allFetched(
		sorted: Bool,
		context: NSManagedObjectContext
	) -> [Album] {
		let fetchRequest = fetchRequest()
		if sorted {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return context.objectsFetched(for: fetchRequest)
	}
	
	// Similar to `Collection.albums`.
	final func songs(sorted: Bool) -> [Song] {
		guard let contents else { return [] }
		
		let unsorted = contents.map { $0 as! Song }
		guard sorted else { return unsorted }
		
		return unsorted.sorted { $0.index < $1.index }
	}
	
	// MARK: - Sorting
	
	final func precedesByNewestFirst(_ other: Album) -> Bool {
		// Leave elements in the same order if they both have no release date, or the same release date.
		
		// Move unknown release date to the end
		guard let otherDate = other.releaseDateEstimate else { return true }
		guard let myDate = releaseDateEstimate else { return false }
		
		return myDate > otherDate
	}
}
