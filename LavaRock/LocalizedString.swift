//
//  LocalizedString.swift
//  LavaRock
//
//  Created by h on 2020-12-05.
//

import Foundation

// Putting all the keys we pass to NSLocalizedString in one place (here) helps us keep them unique, which we need to do to ensure predictable behavior.
// It also helps us use the same phrases in multiple places if appropriate.
final class LocalizedString { // You can't make this an enum, because associated values for enum cases need to be literals.
	
	// Don't pass arguments to the Foundation function NSLocalizedString, because when you choose Editor -> Export for Localization…, Xcode won't include those calls.
	
	// MARK: - Strings Without Variables
	
	// MARK: Standard Buttons
	
	static let cancel = NSLocalizedString("Cancel", comment: "Button title")
	static let done = NSLocalizedString("Done", comment: "Button title")
	
	// MARK: Albums
	
	static let unknownAlbum = NSLocalizedString("Unknown Album", comment: "Placeholder for unknown album title")
	static let unknownArtist = NSLocalizedString("Unknown Artist", comment: "Placeholder for unknown album artist")
	
	// MARK: Options
	
	static let accentColor = NSLocalizedString("Accent Color", comment: "Options heading")
	static let strawberry = NSLocalizedString("Strawberry", comment: "Accent color")
	static let tangerine = NSLocalizedString("Tangerine", comment: "Accent color")
	static let lime = NSLocalizedString("Lime", comment: "Accent color")
	static let blueberry = NSLocalizedString("Blueberry", comment: "Accent color")
	static let grape = NSLocalizedString("Grape", comment: "Accent color")
	
	// MARK: Playback Toolbar
	
	static let previousTrack = NSLocalizedString("Previous track", comment: "Accessibility label")
	static let restart = NSLocalizedString("Restart", comment: "Accessibility label")
	static let play = NSLocalizedString("Play", comment: "Accessibility label")
	static let pause = NSLocalizedString("Pause", comment: "Accessibility label")
	static let nextTrack = NSLocalizedString("Next track", comment: "Accessibility label")
	
	// MARK: "Now Playing" Indicator
	
	static let nowPlaying = NSLocalizedString("Now playing", comment: "Accessibility label")
	static let paused = NSLocalizedString("Paused", comment: "Accessibility label")
	
	// MARK: Editing Mode
	
	static let sort = NSLocalizedString("Sort", comment: "Button title")
	static let sortBy = NSLocalizedString("Sort By", comment: "Action sheet title")
	static let moveToTop = NSLocalizedString("Move to top", comment: "Accessibility label")
	static let moveToBottom = NSLocalizedString("Move to bottom", comment: "Accessibility label")
	
	// MARK: Collections View
	
	static let rename = NSLocalizedString("Rename", comment: "Accessibility label")
	static let renameCollection = NSLocalizedString("Rename Collection", comment: "Alert title")
	static let newCollection = NSLocalizedString("New Collection", comment: "Alert title")
	static let title = NSLocalizedString("Title", comment: "The word for the name of a collection")
	static let defaultCollectionTitle = NSLocalizedString(
		"default_collection_title",
		tableName: nil,
		bundle: Bundle.main,
		value: "New Collection",
		comment: "The title for a collection if you leave it blank. In English, it’s “New Collection”.")
	
	// MARK: Albums View
	
	static let move = NSLocalizedString("Move", comment: "Button title")
	
	// MARK: - Strings With Variables (Format Strings)
	
	// MARK: Strings Without Text Variations
	
	
	
	// MARK: Strings With Text Variations (String Dictionaries)
	
	
	
}
