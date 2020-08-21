//
//  extension Song.swift
//  LavaRock
//
//  Created by h on 2020-08-16.
//

import CoreData
import MediaPlayer

extension Song {
	
	func mpMediaItem() -> MPMediaItem? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let songsQuery = MPMediaQuery.songs()
		songsQuery.addFilterPredicate(
			MPMediaPropertyPredicate(value: persistentID, forProperty: MPMediaItemPropertyPersistentID)
		)
		
		if
			songsQuery.items?.count == 1,
			let songMPMediaItem = songsQuery.items?[0]
		{
			return songMPMediaItem
		} else {
			return nil
		}
	}
	
	// MARK: Getting Stored Attributes in a Nice Format
	
	func titleFormattedOrPlaceholder() -> String {
		if
			let fetchedTitle = mpMediaItem()?.title,
			fetchedTitle != ""
		{
			return fetchedTitle
		} else {
			return "Unknown Song"
		}
	}
	
	func trackNumberFromStoredAttributeFormatted() -> String {
		if trackNumber == 0 {
			return "‒" // This is a figure dash, not a hyphen or an en dash.
		} else {
			return String(trackNumber)
		}
	}
	
}
