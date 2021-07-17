//
//  extension Song.swift
//  LavaRock
//
//  Created by h on 2020-08-16.
//

import CoreData
import MediaPlayer
import OSLog

extension Song: LibraryItem {
	// Enables [Song].reindex()
}

extension Song {
	
	static let log = OSLog(
		subsystem: "LavaRock.Song",
		category: .pointsOfInterest)
	
	// MARK: - Core Data
	
	// Similar to Collection.allFetched and Album.allFetched.
	static func allFetched(
		via managedObjectContext: NSManagedObjectContext,
		ordered: Bool = true
	) -> [Song] {
		let fetchRequest: NSFetchRequest<Song> = fetchRequest()
		if ordered {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return managedObjectContext.objectsFetched(for: fetchRequest)
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
