//
//  Collection.swift
//  LavaRock
//
//  Created by h on 2020-12-17.
//

import CoreData
import OSLog

extension Collection: LibraryItem {
	// Enables `[Collection].reindex()`
	
	final var libraryTitle: String? {
		return title
	}
	
	@MainActor
	final func containsPlayhead() -> Bool {
		guard
			let context = managedObjectContext,
			let containingSong = TapeDeck.shared.songContainingPlayhead(via: context)
		else {
			return false
		}
#if targetEnvironment(simulator)
		return objectID == Sim_Global.currentSong?.container?.container?.objectID
#else
		return objectID == containingSong.container?.container?.objectID
#endif
	}
}
extension Collection: LibraryContainer {}
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
	
	// WARNING: Leaves gaps in the `Album` indices in source `Collection`s, and doesn’t delete empty source `Collection`s. You must call `deleteEmptyCollections` later.
	final func unsafe_moveAlbumsToBeginning_withoutDeleteOrReindexSources(
		with albumIDs: [NSManagedObjectID],
		possiblyToSame: Bool,
		via context: NSManagedObjectContext
	) {
		let albumsToMove = albumIDs.map {
			context.object(with: $0)
		} as! [Album]
		
		// Displace contents
		albums(sorted: false).forEach { $0.index += Int64(albumsToMove.count) }
		
		albumsToMove.enumerated().forEach { (index, album) in
			album.container = self
			album.index = Int64(index)
		}
		
		// In case we moved any albums to this folder that were already here.
		if possiblyToSame {
			var newContents = albums(sorted: true)
			newContents.reindex()
		}
	}
	
	// WARNING: Leaves empty `Collection`s. You must call `deleteEmptyCollections` later.
	final func unsafe_moveAlbumsToEnd_withoutDeleteOrReindexSources(
		with albumIDs: [NSManagedObjectID],
		possiblyToSame: Bool,
		via context: NSManagedObjectContext
	) {
		let albumsToMove = albumIDs.map {
			context.object(with: $0)
		} as! [Album]
		
		let oldNumberOfAlbums = albums(sorted: false).count
		albumsToMove.enumerated().forEach { (index, album) in
			album.container = self
			album.index = Int64(oldNumberOfAlbums + index)
		}
		
		// In case we moved any albums to this folder that were already here.
		if possiblyToSame {
			var newContents = albums(sorted: true)
			newContents.reindex()
		}
	}
}
