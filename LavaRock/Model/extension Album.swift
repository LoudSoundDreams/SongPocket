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
	
	// MARK: - Formatted Attributes
	
	// AppleMusicLibraryManager's importChanges() references this when checking for and making new Collections.
	static let unknownAlbumArtistPlaceholder = LocalizedString.unknownArtist
	
	func titleFormattedOrPlaceholder() -> String {
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
	
	func albumArtistFormattedOrPlaceholder() -> String {
		if
			let representativeItem = mpMediaItemCollection()?.representativeItem,
			let fetchedAlbumArtist = representativeItem.albumArtist, // As of iOS 14.0 beta 5, even if the "album artist" field is blank in Apple Music for Mac (and other tag editors), .albumArtist can still return something. It probably reads the "artist" field from one of the songs. Currently, it returns the same name as the one in the album's header in Apple Music for iOS.
			fetchedAlbumArtist != ""
		{
			return fetchedAlbumArtist
		} else {
			return Self.unknownAlbumArtistPlaceholder
		}
	}
	
	func releaseDateEstimateFormatted() -> String? {
		if let releaseDateEstimate = releaseDateEstimate {
//			let dateFormatter = DateFormatter()
//			dateFormatter.dateStyle = .medium
//			dateFormatter.timeStyle = .none
			
			// Failed attempt to apply ISO8601 format
////			dateFormatter.locale = Locale.current
//			dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//			dateFormatter.dateFormat = "yyyy-MM-dd"
//			dateFormatter.timeZone = TimeZone.current// TimeZone(secondsFromGMT: 0)
////			dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
			
			let releaseDateFormatted = DateFormatter.localizedString(
				from: releaseDateEstimate,
				dateStyle: .medium,
				timeStyle: .none)
			return releaseDateFormatted
		} else {
			return nil
		}
	}
	
}
