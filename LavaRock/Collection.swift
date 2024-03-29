// 2020-12-17

import CoreData

extension Collection: LibraryContainer {}
extension Collection: LibraryItem {
	@MainActor final func containsPlayhead() -> Bool {
#if targetEnvironment(simulator)
		return objectID == Sim_Global.currentSong?.container?.container?.objectID
#else
		guard 
			let currentSong = managedObjectContext?.songInPlayer()
		else { return false }
		return objectID == currentSong.container?.container?.objectID
#endif
	}
}

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
	
	// Similar to `Album.allFetched` and `Song.allFetched`.
	static func allFetched(
		sorted: Bool,
		predicate: NSPredicate? = nil,
		context: NSManagedObjectContext
	) -> [Collection] {
		let fetchRequest = fetchRequest()
		if sorted {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		fetchRequest.predicate = predicate
		return context.objectsFetched(for: fetchRequest)
	}
	
	// MARK: - Albums
	
	// Similar to `Album.songs`.
	final func albums(sorted: Bool) -> [Album] {
		guard let contents else {
			return []
		}
		let unsortedAlbums = contents.map { $0 as! Album }
		if sorted {
			let sortedAlbums = unsortedAlbums.sorted { $0.index < $1.index }
			return sortedAlbums
		} else {
			return unsortedAlbums
		}
	}
	
	// Similar to `Album.renumberSongs`.
	final func renumberAlbums() {
		var albums = albums(sorted: true)
		albums.reindex()
	}
	
	// WARNING: Leaves gaps in the `Album` indices in source `Collection`s, and doesn’t delete empty source `Collection`s. You must call `deleteEmptyCollections` later.
	final func unsafe_InsertAlbums_WithoutDeleteOrReindexSources(
		albumIDs: [NSManagedObjectID],
		via context: NSManagedObjectContext
	) {
		let toMove = albumIDs.map { context.object(with: $0) } as! [Album]
		let targetIndex = 0
		
		// Displace contents
		let toDisplace: [Album] = albums(sorted: false).filter { $0.index >= targetIndex }
		toDisplace.forEach {
			$0.index += Int64(toMove.count)
		}
		
		// Move albums here
		toMove.enumerated().forEach { (offset, album) in
			album.container = self
			album.index = Int64(targetIndex + offset)
		}
		
		// In case we moved any albums to this collection that were already here.
		renumberAlbums()
	}
}
