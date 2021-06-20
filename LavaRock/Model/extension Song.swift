//
//  extension Song.swift
//  LavaRock
//
//  Created by h on 2020-08-16.
//

import CoreData
import MediaPlayer

extension Song: LibraryItem {
	// Enables [song].reindex()
}

extension Song {
	
	// MARK: - Media Player
	
	final func mpMediaItem() -> MPMediaItem? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let songsQuery = MPMediaQuery.songs()
		songsQuery.addFilterPredicate(
			MPMediaPropertyPredicate(
				value: persistentID,
				forProperty: MPMediaItemPropertyPersistentID)
		)
		
		if
			let queriedSongs = songsQuery.items,
			queriedSongs.count == 1,
			let result = queriedSongs.first
		{
			return result
		} else {
			return nil
		}
	}
	
	// MARK: - Formatted Attributes
	
	final func titleFormattedOrPlaceholder() -> String {
		if
			let fetchedTitle = mpMediaItem()?.title,
			fetchedTitle != ""
		{
			return fetchedTitle
		} else {
			return "—" // This is an em dash. It aligns vertically with the figure dash for unknown track numbers.
		}
	}
	
	final func trackNumberFormattedOrPlaceholder() -> String? {
		if
			let fetchedTrackNumber = mpMediaItem()?.albumTrackNumber,
			fetchedTrackNumber != 0
		{
			return String(fetchedTrackNumber)
		} else {
			return "‒" // This is a figure dash, not a hyphen or an en dash.
//			return nil
		}
	}
	
	final func artistFormatted() -> String? {
		if
			let fetchedArtist = mpMediaItem()?.artist,
			fetchedArtist != ""
		{
			return fetchedArtist
		} else {
			return nil
		}
	}
	
}
