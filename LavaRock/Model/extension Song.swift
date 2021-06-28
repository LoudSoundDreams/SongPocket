//
//  extension Song.swift
//  LavaRock
//
//  Created by h on 2020-08-16.
//

import CoreData
import MediaPlayer
import OSLog

extension Song: LibraryItem {
	// Enables [Song].reindex()
}

extension Song {
	
	static let log = OSLog(
		subsystem: "LavaRock.Song",
		category: .pointsOfInterest)
	
	// MARK: - Media Player
	
	final func mpMediaItem() -> MPMediaItem? {
		os_signpost(
			.begin,
			log: Self.log,
			name: "mpMediaItem()")
		defer {
			os_signpost(
				.end,
				log: Self.log,
				name: "mpMediaItem()")
		}
		
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
			return "—" // Em dash
		}
	}
	
	final func trackNumberFormattedOrPlaceholder() -> String {
		if
			let fetchedTrackNumber = mpMediaItem()?.albumTrackNumber,
			fetchedTrackNumber != 0
		{
			return String(fetchedTrackNumber)
		} else {
			return "‒" // Figure dash
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
