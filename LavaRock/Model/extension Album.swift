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
	
	// MARK: - Core Data
	
	// This is the same as in Collection.
	static func allFetched(
		via managedObjectContext: NSManagedObjectContext,
		ordered: Bool = true
	) -> [Album] {
		let fetchRequest: NSFetchRequest<Album> = fetchRequest()
		if ordered {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		return managedObjectContext.objectsFetched(for: fetchRequest)
	}
	
	// Similar to Collection.albums(sorted:).
	final func songs(
		sorted: Bool = true
	) -> [Song] {
		guard let contents = contents else {
			return [Song]()
		}
		
		let unsortedSongs = contents.map { $0 as! Song }
		if sorted {
			let sortedSongs = unsortedSongs.sorted { $0.index < $1.index }
			return sortedSongs
		} else {
			return unsortedSongs
		}
	}
	
	final func sortSongsByDisplayOrder() {
		let songs = songs(sorted: false)
		
		// Note: Behavior is undefined if you compare Songs that correspond to MPMediaItems from different albums.
		// Note: Songs that don't have a corresponding MPMediaItem in the user's Music library will end up at an undefined position in the result. Songs that do will still be in the correct order relative to each other.
		func sortedByDisplayOrderInSameAlbum(songs: [Song]) -> [Song] {
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
				return leftMediaItem.precedesForImporterDisplayOrderOfSongs(inSameAlbum: rightMediaItem)
			}
			
			let result = songsAndMediaItems.map { tuple in tuple.0 }
			return result
		}
		
		var sortedSongs = sortedByDisplayOrderInSameAlbum(songs: songs)
		
		sortedSongs.reindex()
	}
	
	// MARK: - Predicates for Sorting
	
	final func precedesForSortOptionNewestFirst(_ other: Album) -> Bool {
		let myReleaseDate = releaseDateEstimate
		let otherReleaseDate = other.releaseDateEstimate
		// Either can be nil
		
		// At this point, leave Albums in the same order if they both have no release date, or the same release date.
		// However, as of iOS 14.7, when using sorted(by:), returning `true` in the closure doesn't always keep the elements in the same order.
		// Use sortedMaintainingOrderWhen(areEqual:areInOrder:) to guarantee stable sorting.
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
		
		// Sort by newest first
		return myReleaseDate > otherReleaseDate
	}
	
	final func precedesForSortOptionOldestFirst(_ other: Album) -> Bool {
		let myReleaseDate = releaseDateEstimate
		let otherReleaseDate = other.releaseDateEstimate
		// Either can be nil
		
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
		
		// Sort by oldest first
		return myReleaseDate < otherReleaseDate
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
			let fetchedAlbumArtist = representativeItem.albumArtist // As of iOS 14.0 beta 5, even if the "album artist" field is blank in Music for Mac (and other tag editors), .albumArtist can still return something: it probably reads the "artist" field from one of the songs. Currently, it returns the same as what's in the album's header in Music for iOS.
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
