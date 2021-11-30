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
		subsystem: "LavaRock.Collection",
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
		beforeAllOtherCollections allOtherCollections: [Collection],
		title: String,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: Self.log, name: "Create a Collection at the top")
		defer {
			os_signpost(.end, log: Self.log, name: "Create a Collection at the top")
		}
		
		allOtherCollections.forEach { $0.index += 1 }
		
		self.init(context: context)
		self.title = title
		index = 0
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
		
		let collectionsToCombine = idsOfCollectionsToCombine.map { context.object(with: $0) as! Collection }
		var newContents = collectionsToCombine.flatMap { $0.albums() }
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
	final func albums(sorted: Bool = true) -> [Album] {
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
	
	// Works even if any of the `Album`s are already in this `Collection`.
	final func moveAlbumsToBeginning(
		with albumIDs: [NSManagedObjectID],
		via context: NSManagedObjectContext
	) {
		moveAlbumsToBeginning_withoutDelete(
			with: albumIDs,
			via: context)
		
		Self.deleteAllEmpty(via: context) // Also reindexes `self`
	}
	
	// WARNING: Might leave empty `Collection`s. You must call `Collection.deleteAllEmpty` later.
	final func moveAlbumsToBeginning_withoutDelete(
		with albumIDs: [NSManagedObjectID],
		via context: NSManagedObjectContext
	) {
		let albumsToMove = albumIDs.map {
			context.object(with: $0)
		} as! [Album]
		let sourceCollections = Set(albumsToMove.map { $0.container! })
		
		let numberOfAlbumsToMove = albumsToMove.count
		albums().forEach { $0.index += Int64(numberOfAlbumsToMove) }
		albumsToMove.indices.forEach { index in
			let album = albumsToMove[index]
			album.container = self
			album.index = Int64(index)
		}
		// In case we moved any `Album`s to this `Collection` that were already in this `Collection`.
		var newContents = albums()
		newContents.reindex()
		
		sourceCollections.forEach {
			var contents = $0.albums()
			contents.reindex()
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
