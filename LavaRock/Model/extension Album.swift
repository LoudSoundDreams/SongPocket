//
//  extension Album.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import CoreData
import MediaPlayer
import OSLog

extension Album: LibraryItem {
	// Enables [Album].reindex()
}

extension Album: LibraryContainer {
	// Enables isEmpty()
}

extension Album {
	
	static let log = OSLog(
		subsystem: "LavaRock.Album",
		category: .pointsOfInterest)
	
	convenience init(
		for mediaItem: MPMediaItem,
		atEndOf collection: Collection,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: Self.log, name: "Make an Album at the bottom")
		defer {
			os_signpost(.end, log: Self.log, name: "Make an Album at the bottom")
		}
		
		self.init(context: context)
		
		albumPersistentID = Int64(bitPattern: mediaItem.albumPersistentID)
		index = Int64(collection.contents?.count ?? 0)
		
		container = collection
	}
	
	// Use init(for:atEndOf:context:) if possible. It's faster.
	convenience init(
		for mediaItem: MPMediaItem,
		atBeginningOf collection: Collection,
		context: NSManagedObjectContext
	) {
		os_signpost(.begin, log: Self.log, name: "Make an Album at the top")
		defer {
			os_signpost(.end, log: Self.log, name: "Make an Album at the top")
		}
		
		collection.albums(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		
		albumPersistentID = Int64(bitPattern: mediaItem.albumPersistentID)
		index = 0
		
		container = collection
	}
	
	// MARK: - All Instances
	
	// Similar to Collection.allFetched and Song.allFetched.
	static func allFetched(
		ordered: Bool = true,
		context: NSManagedObjectContext
	) -> [Album] {
		let fetchRequest: NSFetchRequest<Album> = fetchRequest()
		if ordered {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return context.objectsFetched(for: fetchRequest)
	}
	
	// WARNING: This leaves gaps in the Album indices within each Collection. You must reindex the Albums within each Collection later.
	static func deleteAllEmpty_withoutReindex(
		context: NSManagedObjectContext
	) {
		let allAlbums = Self.allFetched(ordered: false, context: context) // Use `ordered: true` if you ever make a variant of this method that does reindex the remaining Albums.
		
		allAlbums.forEach { album in
			if album.isEmpty() {
				context.delete(album)
			}
		}
	}
	
	// MARK: - Songs
	
	// Similar to Collection.albums(sorted:).
	final func songs(sorted: Bool = true) -> [Song] {
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
		let mediaItems = songs().compactMap { $0.mpMediaItem() }
		// mpMediaItem() returns nil if the media item is no longer in the Music library. Don't let Songs that we'll delete later disrupt an otherwise in-order Album; just skip over them.
		
		let sortedMediaItems = mediaItems.sorted {
			$0.precedesInDefaultOrder(inSameAlbum: $1)
		}
		
		return mediaItems == sortedMediaItems
	}
	
	final func sortSongsByDefaultOrder() {
		let songs = songs(sorted: false)
		
		// Note: Behavior is undefined if you compare Songs that correspond to MPMediaItems from different albums.
		// Note: Songs that don't have a corresponding MPMediaItem in the user's Music library will end up at an undefined position in the result. Songs that do will still be in the correct order relative to each other.
		func sortedByDefaultOrder(inSameAlbum: [Song]) -> [Song] {
			var songsAndMediaItems = songs.map {
				($0,
				 $0.mpMediaItem()) // Can be nil
			}
			
			songsAndMediaItems.sort { leftTuple, rightTuple in
				guard
					let leftMediaItem = leftTuple.1,
					let rightMediaItem = rightTuple.1
				else {
					return true
				}
				return leftMediaItem.precedesInDefaultOrder(inSameAlbum: rightMediaItem)
			}
			
			let result = songsAndMediaItems.map { tuple in tuple.0 }
			return result
		}
		
		var sortedSongs = sortedByDefaultOrder(inSameAlbum: songs)
		
		sortedSongs.reindex()
	}
	
	// MARK: Creating
	
	final func makeSongsAtEnd(for mediaItems: [MPMediaItem]) {
		os_signpost(.begin, log: Self.log, name: "Make Songs at the bottom")
		defer {
			os_signpost(.end, log: Self.log, name: "Make Songs at the bottom")
		}
		
		mediaItems.forEach {
			let _ = Song(
				for: $0,
				   atEndOf: self,
				   context: managedObjectContext!)
		}
	}
	
	// Use makeSongsAtEnd(for:) if possible. It's faster.
	final func makeSongsAtBeginning(for mediaItems: [MPMediaItem]) {
		os_signpost(.begin, log: Self.log, name: "Make Songs at the top")
		defer {
			os_signpost(.end, log: Self.log, name: "Make Songs at the top")
		}
		
		mediaItems.reversed().forEach {
			let _ = Song(
				for: $0,
				   atBeginningOf: self,
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
		// Either can be nil
		
		// At this point, leave elements in the same order if they both have no release date, or the same release date.
		// However, as of iOS 14.7, when using sorted(by:), returning `true` here doesn't always keep the elements in the same order. Use sortedMaintainingOrderWhen(areEqual:areInOrder:) to guarantee stable sorting.
//		guard myReleaseDate != otherReleaseDate else {
//			return true
//		}
		
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
	
	// Note: Slow.
	final func mpMediaItemCollection() -> MPMediaItemCollection? {
		os_signpost(
			.begin,
			log: Self.log,
			name: "mpMediaItemCollection()")
		defer {
			os_signpost(
				.end,
				log: Self.log,
				name: "mpMediaItemCollection()")
		}
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let albumsQuery = MPMediaQuery.albums() // Does this leave out any songs?
		albumsQuery.addFilterPredicate(
			MPMediaPropertyPredicate(
				value: albumPersistentID,
				forProperty: MPMediaItemPropertyAlbumPersistentID)
		)
		
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
	
	static let placeholderAlbumArtist = LocalizedString.unknownAlbumArtist
	
	final func artworkImage(at size: CGSize) -> UIImage? {
		let artwork = mpMediaItemCollection()?.representativeItem?.artwork
		return artwork?.image(at: size)
	}
	
	final func titleFormattedOrPlaceholder() -> String {
		if
			let representativeItem = mpMediaItemCollection()?.representativeItem,
			let fetchedAlbumTitle = representativeItem.albumTitle,
			fetchedAlbumTitle != ""
		{
			return fetchedAlbumTitle
		} else {
			return LocalizedString.unknownAlbum
		}
	}
	
	final func albumArtistFormattedOrPlaceholder() -> String {
		return albumArtist() ?? Self.placeholderAlbumArtist
	}
	
	final func albumArtist() -> String? {
		if
			let representativeItem = mpMediaItemCollection()?.representativeItem,
			let fetchedAlbumArtist = representativeItem.albumArtist // As of iOS 14.0 developer beta 5, even if the "album artist" field is blank in Music for Mac (and other tag editors), .albumArtist can still return something: it probably reads the "artist" field from one of the songs. Currently, it returns the same as what's in the album's header in Music for iOS.
		{
			return fetchedAlbumArtist
		} else {
			return nil
		}
	}
	
	private static let releaseDateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none
		return dateFormatter
	}()
	
	final func releaseDateEstimateFormatted() -> String? {
		if let releaseDateEstimate = releaseDateEstimate {
			return Self.releaseDateFormatter.string(from: releaseDateEstimate)
		} else {
			return nil
		}
	}
	
}
