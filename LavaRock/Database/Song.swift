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
	// Enables `[Song].reindex()`
	
	final var libraryTitle: String? {
		return songInfo()?.titleOnDisk
	}
	
	@MainActor
	final func containsPlayhead() -> Bool {
		guard
			let context = managedObjectContext,
			let containingSong = TapeDeck.shared.songContainingPlayhead(via: context)
		else {
			return false
		}
		return objectID == containingSong.objectID
	}
}
extension Song {
	convenience init(
		atEndOf album: Album,
		songID: SongID,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: .song, name: "Create a Song at the bottom")
		defer {
			os_signpost(.end, log: .song, name: "Create a Song at the bottom")
		}
		
		self.init(context: context)
		persistentID = songID
		index = Int64(album.contents?.count ?? 0)
		container = album
	}
	
	// Use `init(atEndOf:songID:context:)` if possible. It’s faster.
	convenience init(
		atBeginningOf album: Album,
		songID: SongID,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: .song, name: "Create a Song at the top")
		defer {
			os_signpost(.end, log: .song, name: "Create a Song at the top")
		}
		
		album.songs(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		persistentID = songID
		index = 0
		container = album
	}
	
	// MARK: - All Instances
	
	// Similar to `allFetched`.
	static func allFetched(
		sortedByIndex: Bool,
		via context: NSManagedObjectContext
	) -> [Song] {
		let fetchRequest = fetchRequest()
		if sortedByIndex {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return context.objectsFetched(for: fetchRequest)
	}
	
	static func printAllInDatabaseOrder(
		via context: NSManagedObjectContext
	) {
		var allSongs = allFetched(sortedByIndex: true, via: context)
		allSongs.sort { $0.container!.index < $1.container!.index }
		allSongs.sort { $0.container!.container!.index < $1.container!.container!.index }
		allSongs.forEach {
			print(
				$0.container!.container!.index,
				$0.container!.index,
				$0.index,
				$0.persistentID,
				$0.libraryTitle ?? "")
		}
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
		
		let myFolder = myAlbum.container!
		let otherFolder = otherAlbum.container!
		return myFolder.index < otherFolder.index
	}
	
	// MARK: - Media Player
	
	final func songInfo() -> SongInfo? {
#if targetEnvironment(simulator)
		// To match `mpMediaItem`
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		return Sim_SongInfo.dict[persistentID]
#else
		return mpMediaItem()
#endif
	}
	
	// Slow.
	final func mpMediaItem() -> MPMediaItem? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let songsQuery = MPMediaQuery.songs()
		songsQuery.addFilterPredicate(MPMediaPropertyPredicate(
			value: persistentID,
			forProperty: MPMediaItemPropertyPersistentID))
		
		os_signpost(.begin, log: .song, name: "Query for MPMediaItem")
		defer {
			os_signpost(.end, log: .song, name: "Query for MPMediaItem")
		}
		guard
			let queriedSongs = songsQuery.items,
			queriedSongs.count == 1
		else {
			return nil
		}
		return queriedSongs.first
	}
}
