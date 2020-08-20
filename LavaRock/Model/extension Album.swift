//
//  extension Album.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import CoreData
import MediaPlayer

extension Album {
	
	func mpMediaItemCollection() -> MPMediaItemCollection? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let albumsQuery = MPMediaQuery.albums() // Does this leave out any songs?
		albumsQuery.addFilterPredicate(
			MPMediaPropertyPredicate(
				value: albumPersistentID, forProperty: MPMediaItemPropertyAlbumPersistentID)
		)
		
		if
			albumsQuery.collections?.count == 1,
			let albumMPMediaItemCollection = albumsQuery.collections?[0]
		{
			return albumMPMediaItemCollection
		} else {
			return nil
		}
	}
	
	// MARK: Type Methods
	
	// mergeChangesFromAppleMusicLibrary() references this when checking for and making new Collections.
	static func unknownAlbumArtistPlaceholder() -> String {
		return "Unknown Album Artist"
	}
	
	// MARK: Getting Stored Attributes in a Nice Format
	
	func fetchedTitleOrPlaceholder() -> String {
		if
			let representativeItem = mpMediaItemCollection()?.representativeItem,
			let fetchedAlbumTitle = representativeItem.albumTitle
		{
			return fetchedAlbumTitle
		} else {
			return "Unknown Album"
		}
	}
	
	func fetchedAlbumArtistOrPlaceholder() -> String {
		if
			let representativeItem = mpMediaItemCollection()?.representativeItem,
			let fetchedAlbumArtist = representativeItem.albumArtist
		{
			return fetchedAlbumArtist
		} else {
			return Self.unknownAlbumArtistPlaceholder()
		}
	}
	
	func releaseDateEstimateFormatted() -> String? {
		if let date = releaseDateEstimate {
			let dateFormatter = DateFormatter()
			
			// Insert date formatter options
////			dateFormatter.locale = Locale.current
//			dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//			dateFormatter.dateFormat = "yyyy-MM-dd"
//			dateFormatter.timeZone = TimeZone.current// TimeZone(secondsFromGMT: 0)
////			dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
			
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .none
			
			return dateFormatter.string(from: date)
		} else {
			return nil//"Unknown Date"
		}
	}
	
}
