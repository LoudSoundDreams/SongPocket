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
	// Enables [Collection].reindex()
}

extension Collection: LibraryContainer {
	// Enables isEmpty()
}

extension Collection {
	
	static let log = OSLog(
		subsystem: "LavaRock.Collection",
		category: .pointsOfInterest)
	
	convenience init(
		for mediaItem: MPMediaItem,
		afterAllExistingCollectionsCount numberOfExistingCollections: Int,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: Self.log, name: "Create a Collection at the bottom")
		defer {
			os_signpost(.end, log: Self.log, name: "Create a Collection at the bottom")
		}
		
		self.init(context: context)
		title = mediaItem.albumArtist ?? Album.placeholderAlbumArtist
		index = Int64(numberOfExistingCollections)
	}
	
	// Use init(for:afterAllExistingCollectionsCount:context:) if possible. It's faster.
	convenience init(
		for mediaItem: MPMediaItem,
		before collectionsToInsertBefore: [Collection],
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: Self.log, name: "Create a Collection at the top")
		defer {
			os_signpost(.end, log: Self.log, name: "Create a Collection at the top")
		}
		
		collectionsToInsertBefore.forEach { $0.index += 1 }
		
		self.init(context: context)
		title = mediaItem.albumArtist ?? Album.placeholderAlbumArtist
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
		
		Self.deleteAllEmpty(context: context)
	}
	
	// MARK: - All Instances
	
	// Similar to Album.allFetched and Song.allFetched.
	static func allFetched(
		ordered: Bool = true,
		context: NSManagedObjectContext
	) -> [Collection] {
		let fetchRequest: NSFetchRequest<Collection> = fetchRequest()
		if ordered {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return context.objectsFetched(for: fetchRequest)
	}
	
	static func deleteAllEmpty(context: NSManagedObjectContext) {
		var allCollections = allFetched(context: context)
		
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
	
	// Similar to Album.songs(sorted:).
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
	
	// Works even if any of the Albums are already in this Collection.
	final func moveHere(
		albumsWith albumIDs: [NSManagedObjectID],
		context: NSManagedObjectContext
	) {
		let albumsToMove: [Album] = albumIDs.compactMap {
			context.object(with: $0) as? Album
		}
		let sourceCollections = Set(albumsToMove.map { $0.container! })
		
		let numberOfAlbumsToMove = albumsToMove.count
		albums().forEach { $0.index += Int64(numberOfAlbumsToMove) }
		albumsToMove.indices.forEach { index in
			let album = albumsToMove[index]
			album.container = self
			album.index = Int64(index)
		}
		// In case we moved any Albums to this Collection that were already in this Collection.
		var newContents = albums()
		newContents.reindex()
		
		sourceCollections.forEach {
			var contents = $0.albums()
			contents.reindex()
		}
		
		Self.deleteAllEmpty(context: context) // Also reindexes self
	}
	
	// MARK: - Renaming
	
	final func tryToRename(proposedTitle: String?) {
		if let newTitle = Self.validatedTitleIfPossible(proposedTitle: proposedTitle) {
			title = newTitle
		}
	}
	
	// Returns nil if proposedTitle is nil or "".
	private static func validatedTitleIfPossible(proposedTitle: String?) -> String? {
		guard
			let proposedTitle = proposedTitle,
			proposedTitle != ""
		else {
			return nil
		}
		let trimmedTitle = proposedTitle.prefix(255) // In case the user pastes a dangerous amount of text
		if trimmedTitle != proposedTitle {
			return "\(trimmedTitle)…" // TO DO: Localize?
		} else {
			return "\(trimmedTitle)"
		}
	}
	
}
