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
	
	var libraryTitle: String? { titleFormattedOptional() }
	
	@MainActor
	final func isInPlayer() -> Bool {
		guard
			let context = managedObjectContext,
			let songInPlayer = PlayerWatcher.shared.songInPlayer(context: context)
		else {
			return false
		}
		return objectID == songInPlayer.container?.objectID
	}
}
extension Album: LibraryContainer {}
extension Album {
	convenience init(
		atEndOf collection: Collection,
		mpAlbumID: MPAlbumID,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: .album, name: "Create an Album at the bottom")
		defer {
			os_signpost(.end, log: .album, name: "Create an Album at the bottom")
		}
		
		self.init(context: context)
		albumPersistentID = mpAlbumID
		index = Int64(collection.contents?.count ?? 0)
		container = collection
	}
	
	// Use `init(atEndOf:mpAlbumID:context:)` if possible. It’s faster.
	convenience init(
		atBeginningOf collection: Collection,
		mpAlbumID: MPAlbumID,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: .album, name: "Create an Album at the top")
		defer {
			os_signpost(.end, log: .album, name: "Create an Album at the top")
		}
		
		collection.albums(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		albumPersistentID = mpAlbumID
		index = 0
		container = collection
	}
	
	// MARK: - All Instances
	
	// Similar to `Collection.allFetched` and `Song.allFetched`.
	static func allFetched(
		ordered: Bool,
		via context: NSManagedObjectContext
	) -> [Album] {
		let fetchRequest = Self.fetchRequest()
		if ordered {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return context.objectsFetched(for: fetchRequest)
	}
	
	// WARNING: Leaves gaps in the `Album` indices within `Collection`s, and doesn’t delete empty `Collection`s. You must call `Collection.deleteAllEmpty` later.
	static func unsafe_deleteAllEmpty_withoutReindexOrCascade(
		via context: NSManagedObjectContext
	) {
		let allAlbums = allFetched(ordered: false, via: context) // Use `ordered: true` if you ever create a variant of this method that does reindex the remaining `Album`s.
		
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
		let metadata = songs(sorted: true).compactMap { $0.metadatum() } // Don’t let `Song`s that we’ll delete later disrupt an otherwise in-order `Album`; just skip over them.
		
		let sortedMetadata = metadata.sorted {
			$0.precedesInDefaultOrder(inSameAlbum: $1)
		}
		
		return metadata.indices.allSatisfy { index in
			metadata[index].mpSongID == sortedMetadata[index].mpSongID
		}
	}
	
	final func sortSongsByDefaultOrder() {
		let songs = songs(sorted: false)
		
		// Behavior is undefined if you compare `Song`s that correspond to `SongMetadatum`s from different albums.
		// `Song`s that don’t have a corresponding `SongMetadatum` will end up at an undefined position in the result. `Song`s that do will still be in the correct order relative to each other.
		func sortedByDefaultOrder(inSameAlbum: [Song]) -> [Song] {
			var songsAndMetadata = songs.map {
				(song: $0,
				 metadatum: $0.metadatum()) // Can be `nil`
			}
			
			songsAndMetadata.sort { leftTuple, rightTuple in
				guard
					let leftMetadatum = leftTuple.metadatum,
					let rightMetadatum = rightTuple.metadatum
				else {
					return true
				}
				return leftMetadatum.precedesInDefaultOrder(inSameAlbum: rightMetadatum)
			}
			
			return songsAndMetadata.map { tuple in tuple.song }
		}
		
		var sortedSongs = sortedByDefaultOrder(inSameAlbum: songs)
		
		sortedSongs.reindex()
	}
	
	// MARK: Creating
	
	final func createSongsAtEnd(withMPSongIDs mpSongIDs: [MPSongID]) {
		os_signpost(.begin, log: .album, name: "Create Songs at the bottom")
		defer {
			os_signpost(.end, log: .album, name: "Create Songs at the bottom")
		}
		
		mpSongIDs.forEach {
			let _ = Song(
				atEndOf: self,
				mpSongID: $0,
				context: managedObjectContext!)
		}
	}
	
	// Use `createSongsAtEnd` if possible. It’s faster.
	final func createSongsAtBeginning(withMPSongIDs mpSongIDs: [MPSongID]) {
		os_signpost(.begin, log: .album, name: "Create Songs at the top")
		defer {
			os_signpost(.end, log: .album, name: "Create Songs at the top")
		}
		
		mpSongIDs.reversed().forEach {
			let _ = Song(
				atBeginningOf: self,
				mpSongID: $0,
				context: managedObjectContext!)
		}
	}
	
	// MARK: - Predicates for Sorting
	
	final func precedesForSortOptionNewestFirst(_ other: Album) -> Bool {
		return precedesForSortOption(newestFirstRatherThanOldestFirst: true, other)
	}
	
	final func precedesForSortOptionOldestFirst(_ other: Album) -> Bool {
		return precedesForSortOption(newestFirstRatherThanOldestFirst: false, other)
	}
	
	private func precedesForSortOption(
		newestFirstRatherThanOldestFirst: Bool,
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
		if newestFirstRatherThanOldestFirst {
			return myReleaseDate > otherReleaseDate
		} else {
			return myReleaseDate < otherReleaseDate
		}
	}
	
	// MARK: - Media Player
	
	final func representativeMPMediaItem() -> MPMediaItem? {
		return mpMediaItemCollection()?.representativeItem
	}
	
	// Slow.
	private func mpMediaItemCollection() -> MPMediaItemCollection? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let albumsQuery = MPMediaQuery.albums()
		albumsQuery.addFilterPredicate(
			MPMediaPropertyPredicate(
				value: albumPersistentID,
				forProperty: MPMediaItemPropertyAlbumPersistentID)
		)
		
		os_signpost(.begin, log: .album, name: "Query for MPMediaItemCollection")
		defer {
			os_signpost(.end, log: .album, name: "Query for MPMediaItemCollection")
		}
		if
			let queriedAlbums = albumsQuery.collections,
			queriedAlbums.count == 1,
			let result = queriedAlbums.first
		{
			return result
		} else {
			return nil
		}
	}
	
	// MARK: - Formatted Attributes
	
	static let unknownAlbumArtistPlaceholder = LocalizedString.unknownAlbumArtist
	
	final func artworkImage(at size: CGSize) -> UIImage? {
		let representative = representativeMPMediaItem()
		return representative?.artworkImage(at: size)
	}
	
	final func titleFormattedOrPlaceholder() -> String {
		return titleFormattedOptional() ?? LocalizedString.unknownAlbum
	}
	
	private func titleFormattedOptional() -> String? {
		if
			let representative = representativeMPMediaItem(),
			let fetchedAlbumTitle = representative.albumTitleOnDisk,
			fetchedAlbumTitle != ""
		{
			return fetchedAlbumTitle
		} else {
			return nil
		}
	}
	
	final func albumArtistFormattedOrPlaceholder() -> String {
		if
			let representative = representativeMPMediaItem(),
			let fetchedAlbumArtist = representative.albumArtistOnDisk // As of iOS 14.0 developer beta 5, even if the “album artist” field is blank in Music for Mac (and other tag editors), `.albumArtist` can still return something: it probably reads the “artist” field from one of the songs. Currently, it returns the same as what’s in the album’s header in the built-in Music app for iOS.
		{
			return fetchedAlbumArtist
		} else {
			return Self.unknownAlbumArtistPlaceholder
		}
	}
	
	private static let releaseDateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none
		return dateFormatter
	}()
	final func releaseDateEstimateFormatted() -> String? {
		guard let releaseDateEstimate = releaseDateEstimate else {
			return nil
		}
		return Self.releaseDateFormatter.string(from: releaseDateEstimate)
	}
}
