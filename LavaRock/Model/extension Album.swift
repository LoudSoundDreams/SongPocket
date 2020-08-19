//
//  extension Album.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import CoreData
import MediaPlayer

extension Album {
	
	// Uses Media Player's "representativeItem", but I'm not sure what it considers representative.
	func representativeItem() -> MPMediaItem? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let albumsQuery = MPMediaQuery.albums()
		albumsQuery.addFilterPredicate(
			MPMediaPropertyPredicate(
				value: albumPersistentID, forProperty: MPMediaItemPropertyAlbumPersistentID)
		)
		
//		print(albumsQuery.collections)
//		print(albumsQuery.collectionSections)
//		print(albumsQuery.items)
		
		guard
			albumsQuery.collections?.count == 1,
			let album = albumsQuery.collections?[0]
		else {
			return nil
		}
		
//		print(album.representativeItem?.title!)
		return album.representativeItem
		// What's "representative"?
		// - Not determined by the latest-released song on the album. Do not use it for the album's release date.
	}
	
	// MARK: Type Methods
	
	// mergeChangesFromAppleMusicLibrary() references this when checking for and making new Collections.
	static func unknownAlbumArtistPlaceholder() -> String {
		return "Unknown Artist"
	}
	
	// MARK: Querying Metadata
	
	func representativeItemArtworkImage() -> UIImage? {
		let mediaItemArtwork = representativeItem()?.artwork
		let artworkImage = mediaItemArtwork?.image(
			at: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)) // Make this a parameter.
		return artworkImage
	}
	
	// MARK: Getting Stored Attributes in a Nice Format
	
	func albumArtistOrPlaceholder() -> String {
		if
			let storedAlbumArtist = albumArtist,
			albumArtist != ""
		{
			return storedAlbumArtist
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
	
	// There's a similar method in `extension Song`. Make this generic?
	func titleOrPlaceholder() -> String {
		if
			let storedTitle = title,
			storedTitle != ""
		{
			return storedTitle
		} else {
			return "Unknown Album"
		}
	}
	
}
