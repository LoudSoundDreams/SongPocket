//
//  Album.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import CoreData
import MediaPlayer
import OSLog

extension Album: LibraryItem {
	// Enables `[Album].reindex()`
	
	final var libraryTitle: String? { representativeTitleFormattedOptional() }
	
	@MainActor
	final func containsPlayhead() -> Bool {
		guard
			let context = managedObjectContext,
			let containingSong = TapeDeck.shared.songContainingPlayhead(via: context)
		else {
			return false
		}
		return objectID == containingSong.container?.objectID
	}
}
extension Album: LibraryContainer {}
extension Album {
	convenience init(
		atEndOf collection: Collection,
		albumID: AlbumID,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: .album, name: "Create an Album at the bottom")
		defer {
			os_signpost(.end, log: .album, name: "Create an Album at the bottom")
		}
		
		self.init(context: context)
		albumPersistentID = albumID
		index = Int64(collection.contents?.count ?? 0)
		container = collection
	}
	
	// Use `init(atEndOf:albumID:context:)` if possible. It’s faster.
	convenience init(
		atBeginningOf collection: Collection,
		albumID: AlbumID,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: .album, name: "Create an Album at the top")
		defer {
			os_signpost(.end, log: .album, name: "Create an Album at the top")
		}
		
		collection.albums(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		albumPersistentID = albumID
		index = 0
		container = collection
	}
	
	// MARK: - All Instances
	
	// Similar to `Collection.allFetched` and `Song.allFetched`.
	static func allFetched(
		sortedByIndex: Bool,
		via context: NSManagedObjectContext
	) -> [Album] {
		let fetchRequest = fetchRequest()
		if sortedByIndex {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return context.objectsFetched(for: fetchRequest)
	}
	
	// WARNING: Leaves gaps in the `Album` indices within `Collection`s, and doesn’t delete empty `Collection`s. You must call `Collection.deleteAllEmpty` later.
	static func unsafe_deleteAllEmpty_withoutReindexOrCascade(
		via context: NSManagedObjectContext
	) {
		let allAlbums = allFetched(sortedByIndex: false, via: context) // Use `ordered: true` if you ever create a variant of this method that does reindex the remaining `Album`s.
		
		allAlbums.forEach { album in
			if album.isEmpty() {
				context.delete(album)
			}
		}
	}
	
	// MARK: - Songs
	
	// Similar to `Collection.albums`.
	final func songs(sorted: Bool) -> [Song] {
		guard let contents = contents else {
			return []
		}
		let unsortedSongs = contents.map { $0 as! Song }
		if sorted {
			let sortedSongs = unsortedSongs.sorted { $0.index < $1.index }
			return sortedSongs
		} else {
			return unsortedSongs
		}
	}
	
	final func songsAreInDefaultOrder() -> Bool {
		let infos = songs(sorted: true).compactMap { $0.songInfo() } // Don’t let `Song`s that we’ll delete later disrupt an otherwise in-order `Album`; just skip over them.
		
		let sortedInfos = infos.sorted {
			$0.precedesInDefaultOrder(inSameAlbum: $1)
		}
		
		return infos.indices.allSatisfy { index in
			infos[index].songID == sortedInfos[index].songID
		}
	}
	
	final func sortSongsByDefaultOrder() {
		let songs = songs(sorted: false)
		
		// Behavior is undefined if you compare `Song`s that correspond to `SongInfo`s from different albums.
		// `Song`s that don’t have a corresponding `SongInfo` will end up at an undefined position in the result. `Song`s that do will still be in the correct order relative to each other.
		func sortedByDefaultOrder(inSameAlbum: [Song]) -> [Song] {
			var songsAndInfos = songs.map {
				(song: $0,
				 info: $0.songInfo()) // Can be `nil`
			}
			
			songsAndInfos.sort { leftTuple, rightTuple in
				guard
					let leftInfo = leftTuple.info,
					let rightInfo = rightTuple.info
				else {
					return true
				}
				return leftInfo.precedesInDefaultOrder(inSameAlbum: rightInfo)
			}
			
			return songsAndInfos.map { tuple in tuple.song }
		}
		
		var sortedSongs = sortedByDefaultOrder(inSameAlbum: songs)
		
		sortedSongs.reindex()
	}
	
	// MARK: Creating
	
	final func createSongsAtEnd(with songIDs: [SongID]) {
		os_signpost(.begin, log: .album, name: "Create Songs at the bottom")
		defer {
			os_signpost(.end, log: .album, name: "Create Songs at the bottom")
		}
		
		songIDs.forEach {
			let _ = Song(
				atEndOf: self,
				songID: $0,
				context: managedObjectContext!)
		}
	}
	
	// Use `createSongsAtEnd` if possible. It’s faster.
	final func createSongsAtBeginning(with songIDs: [SongID]) {
		os_signpost(.begin, log: .album, name: "Create Songs at the top")
		defer {
			os_signpost(.end, log: .album, name: "Create Songs at the top")
		}
		
		songIDs.reversed().forEach {
			let _ = Song(
				atBeginningOf: self,
				songID: $0,
				context: managedObjectContext!)
		}
	}
	
	// MARK: - Predicates for Sorting
	
	final func precedesByNewestFirst(_ other: Album) -> Bool {
		return precedes(byNewestFirstRatherThanOldestFirst: true, other)
	}
	
	final func precedesByOldestFirst(_ other: Album) -> Bool {
		return precedes(byNewestFirstRatherThanOldestFirst: false, other)
	}
	
	private func precedes(
		byNewestFirstRatherThanOldestFirst: Bool,
		_ other: Album
	) -> Bool {
		let myReleaseDate = releaseDateEstimate
		let otherReleaseDate = other.releaseDateEstimate
		// Either can be `nil`
		
		// At this point, leave elements in the same order if they both have no release date, or the same release date.
		// However, as of iOS 14.7, when using `sorted(by:)`, using `guard myReleaseDate != otherReleaseDate else { return true }` here doesn’t always keep the elements in the same order. Call this method in `sortedMaintainingOrderWhen` to guarantee stable sorting.
		
		// Move unknown release date to the end
		guard let otherReleaseDate = otherReleaseDate else {
			return true
		}
		guard let myReleaseDate = myReleaseDate else {
			return false
		}
		
		// Sort by release date
		if byNewestFirstRatherThanOldestFirst {
			return myReleaseDate > otherReleaseDate
		} else {
			return myReleaseDate < otherReleaseDate
		}
	}
	
	// MARK: - Media Player
	
	final func representativeSongInfo() -> SongInfo? {
#if targetEnvironment(simulator)
		return songs(sorted: true).first?.songInfo()
#else
		return mpMediaItemCollection()?.representativeItem
#endif
	}
	
	// Slow.
	private func mpMediaItemCollection() -> MPMediaItemCollection? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let albumsQuery = MPMediaQuery.albums()
		albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(
			value: albumPersistentID,
			forProperty: MPMediaItemPropertyAlbumPersistentID))
		
		os_signpost(.begin, log: .album, name: "Query for MPMediaItemCollection")
		defer {
			os_signpost(.end, log: .album, name: "Query for MPMediaItemCollection")
		}
		guard
			let queriedAlbums = albumsQuery.collections,
			queriedAlbums.count == 1
		else {
			return nil
		}
		return queriedAlbums.first
	}
	
	// MARK: - Formatted Attributes
	
	static let unknownTitlePlaceholder = LRString.unknownAlbum
	final func representativeTitleFormattedOrPlaceholder() -> String {
		guard let title = representativeTitleFormattedOptional() else {
			return Self.unknownTitlePlaceholder
		}
		return title
	}
	final func representativeTitleFormattedOptional() -> String? {
		guard
			let title = representativeSongInfo()?.albumTitleOnDisk,
			title != ""
		else {
			return nil
		}
		return title
	}
	
	final func representativeAlbumArtistFormattedOrPlaceholder() -> String {
		guard let albumArtist = representativeAlbumArtistFormattedOptional() else {
			return LRString.unknownAlbumArtist
		}
		return albumArtist
	}
	final func representativeAlbumArtistFormattedOptional() -> String? {
		guard
			let albumArtist = representativeSongInfo()?.albumArtistOnDisk, // As of iOS 14.0 developer beta 5, even if the “album artist” field is blank in Apple Music for Mac (and other tag editors), `.albumArtist` can still return something: it probably reads the “artist” field from one of the songs. Currently, it returns the same as what’s in the album’s header in Apple Music for iOS.
			albumArtist != ""
		else {
			return nil
		}
		return albumArtist
	}
	
	final func releaseDateEstimateFormattedOptional() -> String? {
		return releaseDateEstimate?.formatted(date: .abbreviated, time: .omitted)
	}
}
