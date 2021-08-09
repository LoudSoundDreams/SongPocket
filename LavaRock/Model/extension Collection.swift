//
//  extension Collection.swift
//  LavaRock
//
//  Created by h on 2020-12-17.
//

import CoreData
import MediaPlayer
import OSLog

extension Collection: LibraryItem {
	// Enables [Collection].reindex()
}

extension Collection: LibraryContainer {
	// Enables isEmpty()
}

extension Collection {
	
	static let log = OSLog(
		subsystem: "LavaRock.Collection",
		category: .pointsOfInterest)
	
	// If nil, `proposedTitle` was nil or "".
	static func validatedTitleOptional(
		from proposedTitle: String?
	) -> String? {
		guard
			let proposedTitle = proposedTitle,
			proposedTitle != ""
		else {
			return nil
		}

		let trimmedTitle = proposedTitle.prefix(255) // In case the user pastes a dangerous amount of text
		if trimmedTitle != proposedTitle {
			return trimmedTitle + "…" // TO DO: Localize?
		} else {
			return String(trimmedTitle)
		}
	}
	
	// MARK: - Initializers
	
	convenience init(
		for mediaItem: MPMediaItem,
		afterAllExistingCollectionsCount numberOfExistingCollections: Int,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: Self.log, name: "Make a Collection at the bottom")
		defer {
			os_signpost(.end, log: Self.log, name: "Make a Collection at the bottom")
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
		os_signpost(.begin, log: Self.log, name: "Make a Collection at the top")
		defer {
			os_signpost(.end, log: Self.log, name: "Make a Collection at the top")
		}
		
		collectionsToInsertBefore.forEach { $0.index += 1 }
		
		self.init(context: context)
		
		title = mediaItem.albumArtist ?? Album.placeholderAlbumArtist
		index = 0
	}
	
	// MARK: - Core Data
	
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
	
	// Similar to Album.songs(sorted:).
	final func albums(
		sorted: Bool = true
	) -> [Album] {
		guard let contents = contents else {
			return [Album]()
		}
		
		let unsortedAlbums = contents.map { $0 as! Album }
		if sorted {
			let sortedAlbums = unsortedAlbums.sorted { $0.index < $1.index }
			return sortedAlbums
		} else {
			return unsortedAlbums
		}
	}
	
	static func deleteAllEmpty(context: NSManagedObjectContext) {
		var allCollections = Collection.allFetched(context: context)
		
		allCollections.indices.reversed().forEach { index in
			let collection = allCollections[index]
			if collection.isEmpty() {
				context.delete(collection)
				allCollections.remove(at: index)
			}
		}
		
		allCollections.reindex()
	}
	
	// WARNING: Unsafe; leaves Collections in an incoherent state.
	// After calling this, you must delete empty Collections and reindex all Collections.
	static func makeByCombining_withoutDeletingOrReindexing(
		_ selectedCollections: [Collection],
		title titleOfCombinedCollection: String,
		index indexOfCombinedCollection: Int64,
		context: NSManagedObjectContext
	) -> Collection {
		var selectedAlbums = selectedCollections.flatMap { selectedCollection in
			selectedCollection.albums()
		}
		selectedAlbums.reindex()
		
		let combinedCollection = Collection(context: context)
		combinedCollection.index = indexOfCombinedCollection
		combinedCollection.title = titleOfCombinedCollection
		selectedAlbums.forEach { $0.container = combinedCollection }
		
		return combinedCollection
	}
	
}
