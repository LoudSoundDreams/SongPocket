//
//  Song.swift
//  LavaRock
//
//  Created by h on 2020-08-16.
//

import CoreData
import MediaPlayer
import OSLog

extension Song: LibraryItem {
	var libraryTitle: String? { mpMediaItem()?.title }
	
	// Enables `[Song].reindex()`
}

extension Song {
	
	static let log = OSLog(
		subsystem: "LavaRock.Song",
		category: .pointsOfInterest)
	
	convenience init(
		atEndOf album: Album,
		for mediaItem: MPMediaItem,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: Self.log, name: "Create a Song at the bottom")
		defer {
			os_signpost(.end, log: Self.log, name: "Create a Song at the bottom")
		}
		
		self.init(context: context)
		persistentID = Int64(bitPattern: mediaItem.persistentID)
		index = Int64(album.contents?.count ?? 0)
		container = album
	}
	
	// Use `init(atEndOf:for:context:)` if possible. It’s faster.
	convenience init(
		atBeginningOf album: Album,
		for mediaItem: MPMediaItem,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: Self.log, name: "Create a Song at the top")
		defer {
			os_signpost(.end, log: Self.log, name: "Create a Song at the top")
		}
		
		album.songs(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		persistentID = Int64(bitPattern: mediaItem.persistentID)
		index = 0
		container = album
	}
	
	// MARK: - All Instances
	
	// Similar to `Collection.allFetched` and `Album.allFetched`.
	static func allFetched(
		ordered: Bool,
		via context: NSManagedObjectContext
	) -> [Song] {
		let fetchRequest: NSFetchRequest<Song> = fetchRequest()
		if ordered {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return context.objectsFetched(for: fetchRequest)
	}
	
	// MARK: - Predicates for Sorting
	
	final func precedesInUserCustomOrder(_ other: Song) -> Bool {
		// Checking `Song` index first and `Collection` index last is slightly faster than vice versa.
		guard index == other.index else {
			return index < other.index
		}
		
		let myAlbum = container!
		let otherAlbum = other.container!
		guard myAlbum.index == other.index else {
			return myAlbum.index < otherAlbum.index
		}
		
		let myCollection = myAlbum.container!
		let otherCollection = otherAlbum.container!
		return myCollection.index < otherCollection.index
	}
	
	// MARK: - Media Player
	
	// Note: Slow.
	final func mpMediaItem() -> MPMediaItem? {
		os_signpost(
			.begin,
			log: Self.log,
			name: "mpMediaItem()")
		defer {
			os_signpost(
				.end,
				log: Self.log,
				name: "mpMediaItem()")
		}
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let songsQuery = MPMediaQuery.songs()
		songsQuery.addFilterPredicate(
			MPMediaPropertyPredicate(
				value: persistentID,
				forProperty: MPMediaItemPropertyPersistentID)
		)
		
		if
			let queriedSongs = songsQuery.items,
			queriedSongs.count == 1,
			let result = queriedSongs.first
		{
			return result
		} else {
			return nil
		}
	}
	
}
