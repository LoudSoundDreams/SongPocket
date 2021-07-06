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
	
	static let unknownAlbumArtistPlaceholder = LocalizedString.unknownAlbumArtist
	
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
		return albumArtist() ?? Self.unknownAlbumArtistPlaceholder
	}
	
	final func albumArtist() -> String? {
		if
			let representativeItem = mpMediaItemCollection()?.representativeItem,
			let fetchedAlbumArtist = representativeItem.albumArtist // As of iOS 14.0 beta 5, even if the "album artist" field is blank in the Music app for Mac (and other tag editors), .albumArtist can still return something. It probably reads the "artist" field from one of the songs. Currently, it returns the same name as the one in the album's header in the built-in Music app for iOS.
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
