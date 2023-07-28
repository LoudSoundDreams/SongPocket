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
		return objectID == containingSong.container?.container?.objectID
	}
}
extension Collection: LibraryContainer {}
extension Collection {
	convenience init(
		afterAllOtherCount existingCount: Int,
		title: String,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: .folder, name: "Create a folder at the bottom")
		defer {
			os_signpost(.end, log: .folder, name: "Create a folder at the bottom")
		}
		
		self.init(context: context)
		self.title = title
		index = Int64(existingCount)
	}
	
	// Use `init(afterAllOtherCount:title:context:)` if possible. It’s faster.
	convenience init(
		index: Int64,
		before displaced: [Collection],
		title: String,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: .folder, name: "Create a folder at the top")
		defer {
			os_signpost(.end, log: .folder, name: "Create a folder at the top")
		}
		
		displaced.forEach { $0.index += 1 }
		
		self.init(context: context)
		self.title = title
		self.index = index
	}
	
	// MARK: - All instances
	
	// Similar to `Album.allFetched` and `Song.allFetched`.
	static func allFetched(
		ordered: Bool,
		predicate: NSPredicate? = nil,
		via context: NSManagedObjectContext
	) -> [Collection] {
		let fetchRequest = fetchRequest()
		if ordered {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		fetchRequest.predicate = predicate
		return context.objectsFetched(for: fetchRequest)
	}
	
	static func deleteAllEmpty(via context: NSManagedObjectContext) {
		var all = allFetched(ordered: true, via: context)
		
		all.enumerated().reversed().forEach { (index, folder) in
			if folder.isEmpty() {
				context.delete(folder)
				all.remove(at: index)
			}
		}
		
		all.reindex()
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
	
	final func moveAlbumsToBeginning(
		with albumIDs: [NSManagedObjectID],
		possiblyToSame: Bool,
		via context: NSManagedObjectContext
	) {
		unsafe_moveAlbumsToBeginning_withoutDeleteOrReindexSources(
			with: albumIDs,
			possiblyToSame: possiblyToSame,
			via: context)
		
		Self.deleteAllEmpty(via: context) // Also reindexes `self`
	}
	
	// WARNING: Leaves gaps in the `Album` indices in source `Collection`s, and doesn’t delete empty source `Collection`s. You must call `Collection.deleteAllEmpty` later.
	final func unsafe_moveAlbumsToBeginning_withoutDeleteOrReindexSources(
		with albumIDs: [NSManagedObjectID],
		possiblyToSame: Bool,
		via context: NSManagedObjectContext
	) {
		let albumsToMove = albumIDs.map {
			context.object(with: $0)
		} as! [Album]
		
		let numberOfAlbumsToMove = albumsToMove.count
		albums(sorted: false).forEach { $0.index += Int64(numberOfAlbumsToMove) }
		
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
	
	// WARNING: Leaves empty `Collection`s. You must call `Collection.deleteAllEmpty` later.
	final func unsafe_moveAlbumsToEnd_withoutDeleteOrReindexSources(
		with albumIDs: [NSManagedObjectID],
		possiblyToSame: Bool,
		via context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: .folder, name: "Move albums to end")
		defer {
			os_signpost(.end, log: .folder, name: "Move albums to end")
		}
		
		os_signpost(.begin, log: .folder, name: "Fetch albums")
		let albumsToMove = albumIDs.map {
			context.object(with: $0)
		} as! [Album]
		os_signpost(.end, log: .folder, name: "Fetch albums")
		
		os_signpost(.begin, log: .folder, name: "Count albums already in this folder")
		let oldNumberOfAlbums = albums(sorted: false).count
		os_signpost(.end, log: .folder, name: "Count albums already in this folder")
		albumsToMove.enumerated().forEach { (index, album) in
			os_signpost(.begin, log: .folder, name: "Update album attributes")
			album.container = self
			album.index = Int64(oldNumberOfAlbums + index)
			os_signpost(.end, log: .folder, name: "Update album attributes")
		}
		
		// In case we moved any albums to this folder that were already here.
		if possiblyToSame {
			var newContents = albums(sorted: true)
			newContents.reindex()
		}
	}
}
