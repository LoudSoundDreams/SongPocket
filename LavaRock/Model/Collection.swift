//
//  Collection.swift
//  LavaRock
//
//  Created by h on 2020-12-17.
//

import CoreData
import MediaPlayer
import OSLog

extension Collection: LibraryItem {
	var libraryTitle: String? { title }
	
	// Enables `[Collection].reindex()`
}

extension Collection: LibraryContainer {
}

extension Collection {
	
	static let log = OSLog(
		subsystem: "Collection",
		category: .pointsOfInterest)
	
	convenience init(
		afterAllOtherCollectionsCount numberOfExistingCollections: Int,
		title: String,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: Self.log, name: "Create a Collection at the bottom")
		defer {
			os_signpost(.end, log: Self.log, name: "Create a Collection at the bottom")
		}
		
		self.init(context: context)
		self.title = title
		index = Int64(numberOfExistingCollections)
	}
	
	// Use `init(afterAllOtherCollectionsCount:title:context:)` if possible. It’s faster.
	convenience init(
		index: Int64,
		before displacedCollections: [Collection],
		title: String,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: Self.log, name: "Create a Collection at the top")
		defer {
			os_signpost(.end, log: Self.log, name: "Create a Collection at the top")
		}
		
		displacedCollections.forEach { $0.index += 1 }
		
		self.init(context: context)
		self.title = title
		self.index = index
	}
	
	convenience init(
		combiningCollectionsInOrderWith idsOfCollectionsToCombine: [NSManagedObjectID],
		title: String,
		index: Int64,
		context: NSManagedObjectContext
	) {
		self.init(context: context)
		self.title = title
		self.index = index
		
		let collectionsToCombine = idsOfCollectionsToCombine.map { context.object(with: $0) } as! [Collection]
		var newContents = collectionsToCombine.flatMap { $0.albums(sorted: true) }
		newContents.reindex()
		newContents.forEach { $0.container = self }
		
		Self.deleteAllEmpty(via: context)
	}
	
	// MARK: - All Instances
	
	// Similar to `Album.allFetched` and `Song.allFetched`.
	static func allFetched(
		ordered: Bool = true,
		via context: NSManagedObjectContext
	) -> [Collection] {
		let fetchRequest: NSFetchRequest<Collection> = fetchRequest()
		if ordered {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return context.objectsFetched(for: fetchRequest)
	}
	
	static func deleteAllEmpty(via context: NSManagedObjectContext) {
		var allCollections = allFetched(via: context)
		
		allCollections.indices.reversed().forEach { index in
			let collection = allCollections[index]
			if collection.isEmpty() {
				context.delete(collection)
				allCollections.remove(at: index)
			}
		}
		
		allCollections.reindex()
	}
	
	// MARK: - Albums
	
	// Similar to `Album.songs(sorted:)`.
	final func albums(sorted: Bool) -> [Album] {
		guard let contents = contents else {
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
		possiblyToSameCollection: Bool,
		via context: NSManagedObjectContext
	) {
		moveAlbumsToBeginning_withoutDeleteOrReindexSourceCollections(
			with: albumIDs,
			possiblyToSameCollection: possiblyToSameCollection,
			via: context)
		
		Self.deleteAllEmpty(via: context) // Also reindexes `self`
	}
	
	// WARNING: Leaves gaps in the `Album` indices in source `Collection`s, and doesn't delete empty source `Collection`s. You must call `Collection.deleteAllEmpty` later.
	final func moveAlbumsToBeginning_withoutDeleteOrReindexSourceCollections(
		with albumIDs: [NSManagedObjectID],
		possiblyToSameCollection: Bool,
		via context: NSManagedObjectContext
	) {
		let albumsToMove = albumIDs.map {
			context.object(with: $0)
		} as! [Album]
		
		let numberOfAlbumsToMove = albumsToMove.count
		albums(sorted: false).forEach { $0.index += Int64(numberOfAlbumsToMove) }
		
		albumsToMove.indices.forEach { index in
			let album = albumsToMove[index]
			album.container = self
			album.index = Int64(index)
		}
		
		// In case we moved any `Album`s to this `Collection` that were already in this `Collection`.
		if possiblyToSameCollection {
			var newContents = albums(sorted: true)
			newContents.reindex()
		}
	}
	
	// WARNING: Might leave empty `Collection`s. You must call `Collection.deleteAllEmpty` later.
	final func moveAlbumsToEnd_withoutDeleteOrReindexSourceCollections(
		with albumIDs: [NSManagedObjectID],
		possiblyToSameCollection: Bool,
		via context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: Self.log, name: "Move Albums to end")
		defer {
			os_signpost(.end, log: Self.log, name: "Move Albums to end")
		}
		
		os_signpost(.begin, log: Self.log, name: "Fetch Albums")
		let albumsToMove = albumIDs.map {
			context.object(with: $0)
		} as! [Album]
		os_signpost(.end, log: Self.log, name: "Fetch Albums")
		
		os_signpost(.begin, log: Self.log, name: "Count Albums already in this Collection")
		let oldNumberOfAlbums = albums(sorted: false).count
		os_signpost(.end, log: Self.log, name: "Count Albums already in this Collection")
		albumsToMove.indices.forEach { index in
			os_signpost(.begin, log: Self.log, name: "Update Album attributes")
			let album = albumsToMove[index]
			album.container = self
			album.index = Int64(oldNumberOfAlbums + index)
			os_signpost(.end, log: Self.log, name: "Update Album attributes")
		}
		
		// In case we moved any `Album`s to this `Collection` that were already in this `Collection`.
		if possiblyToSameCollection {
			var newContents = albums(sorted: true)
			newContents.reindex()
		}
	}
	
	// MARK: - Renaming
	
	final func tryToRename(proposedTitle: String?) {
		if let newTitle = Self.validatedTitleIfPossible(proposedTitle: proposedTitle) {
			title = newTitle
		}
	}
	
	// Returns `nil` if `proposedTitle` is `nil` or `""`.
	private static func validatedTitleIfPossible(proposedTitle: String?) -> String? {
		guard
			let proposedTitle = proposedTitle,
			proposedTitle != ""
		else {
			return nil
		}
		let trimmedTitle = proposedTitle.prefix(255) // In case the user pastes a dangerous amount of text
		if trimmedTitle != proposedTitle {
			return "\(trimmedTitle)\(LocalizedString.ellipsis)"
		} else {
			return "\(trimmedTitle)"
		}
	}
	
}
