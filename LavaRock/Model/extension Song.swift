//
//  extension Song.swift
//  LavaRock
//
//  Created by h on 2020-08-16.
//

import CoreData
import MediaPlayer

extension Song {
	
	func artworkImage() -> UIImage? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let songsQuery = MPMediaQuery.songs()
		songsQuery.addFilterPredicate(
			MPMediaPropertyPredicate(
				value: persistentID, forProperty: MPMediaItemPropertyPersistentID)
		)
		
		guard
			songsQuery.items?.count == 1,
			let song = songsQuery.items?[0]
		else {
			return nil
		}
		let mediaItemArtwork = song.artwork
		let artworkImage = mediaItemArtwork?.image(
			at: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)) // Make this a parameter.
		return artworkImage
	}
	
	// MARK: Getting Stored Attributes in a Nice Format
	
	// There's a similar method in `extension Album`. Make this generic?
	func titleOrPlaceholder() -> String {
		if
			let storedTitle = title,
			storedTitle != ""
		{
			return storedTitle
		} else {
			return "Unknown Song"
		}
	}
	
	func trackNumberFormatted() -> String {
		if trackNumber == 0 {
			return "•"
		} else {
			return String(trackNumber)
		}
	}
	
}
