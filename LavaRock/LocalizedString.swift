//
//  LocalizedString.swift
//  LavaRock
//
//  Created by h on 2020-12-05.
//

import Foundation

// Putting all the keys we pass to NSLocalizedString in one place (here) helps us keep them unique, which we need to do to ensure predictable behavior.
// It also helps us use the same phrases in multiple places if appropriate.
struct LocalizedString { // You can't make this an enum, because raw values for enum cases need to be literals.
	
	// Don't pass arguments to the Foundation function NSLocalizedString, because when you choose Editor -> Export for Localization…, Xcode won't include those calls.
	
	private init() { }
	
	// MARK: - Without Variables
	
	// MARK: Standard Buttons
	
	static let cancel = NSLocalizedString("Cancel", comment: "Button")
	static let save = NSLocalizedString("Save", comment: "Button")
	static let done = NSLocalizedString("Done", comment: "Button")
	static let ok = NSLocalizedString("OK", comment: "Button")
	
	// MARK: Standard Phrases
	
	static let loadingWithEllipsis = NSLocalizedString("Loading…", comment: "Status message")
	
	// MARK: Albums
	
	static let unknownAlbum = NSLocalizedString("Unknown Album", comment: "Placeholder for unknown album title")
	static let unknownArtist = NSLocalizedString("Unknown Album Artist", comment: "Placeholder for unknown album artist")
	
	// MARK: Options
	
	static let accentColor = NSLocalizedString("Accent Color", comment: "Options section header")
	static let strawberry = NSLocalizedString("Strawberry", comment: "Accent color")
	static let tangerine = NSLocalizedString("Tangerine", comment: "Accent color")
	static let lime = NSLocalizedString("Lime", comment: "Accent color")
	static let blueberry = NSLocalizedString("Blueberry", comment: "Accent color")
	static let grape = NSLocalizedString("Grape", comment: "Accent color")
	
	static let tipJar = NSLocalizedString("Tip Jar", comment: "Options section header")
	static let tipJarFooter = NSLocalizedString("Hi, I’m H. Tips help me improve Songpocket. They give you no extra features, and are completely optional. I would especially appreciate tips after updates to the app!", comment: "Options → Tip Jar section footer")
	static let tipThankYouMessageWithPaddingSpaces = NSLocalizedString(" Thank You! ", comment: "After leaving a tip, the thank-you message that appears between two heart emojis. Include padding spaces if your language uses them.")
	
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
	
	static let sort = NSLocalizedString("Sort", comment: "Button")
	static let sortBy = NSLocalizedString("Sort By", comment: "Action sheet title")
	static let moveToTop = NSLocalizedString("Move to top", comment: "Accessibility label")
	static let moveToBottom = NSLocalizedString("Move to bottom", comment: "Accessibility label")
	
	// MARK: Collections View
	
	static let allowAccessToMusic = NSLocalizedString("Allow Access to Music", comment: "Button")
	static let rename = NSLocalizedString("Rename", comment: "Accessibility label")
	static let renameCollection = NSLocalizedString("Rename Collection", comment: "Alert title")
	static let newCollection = NSLocalizedString("New Collection", comment: "Alert title")
	static let title = NSLocalizedString("Title", comment: "The word for the name of a collection, album, or song")
	static let defaultCollectionTitle = NSLocalizedString(
		"default_collection_title",
		tableName: nil,
		bundle: Bundle.main,
		value: "New Collection",
		comment: "Title for a collection if you leave it blank. In English, it’s “New Collection”.")
	
	// MARK: Albums View
	
	static let move = NSLocalizedString("Move", comment: "Button")
	static let newestFirst = NSLocalizedString("Newest First", comment: "Button")
	static let oldestFirst = NSLocalizedString("Oldest First", comment: "Button")
	static let moveHere = NSLocalizedString("Move Here", comment: "Button")
	
	// MARK: Songs View
	
	static let albumArtwork = NSLocalizedString("Album artwork", comment: "Accessibility label")
	static let playAlbumStartingHere = NSLocalizedString("Play All Starting Here", comment: "Button")
	static let queueAlbumStartingHere = NSLocalizedString("Queue All Starting Here", comment: "Button")
	static let queueSong = NSLocalizedString("Queue Song", comment: "Button")
	static let didEnqueueSongsAlertMessage = NSLocalizedString(
		"did_enqueue_songs_alert_message",
		tableName: nil,
		bundle: Bundle.main,
		value: "You can edit the queue in the built-in Music app.",
		comment: "Body text of the alert that appears after the user adds songs to the queue.")
	static let dontShowAgain = NSLocalizedString("Don’t Show Again", comment: "Button")
	static let trackNumber = NSLocalizedString("Track Number", comment: "Button")
	
	// MARK: - With Variables, but Without Text Variations (Format Strings)
	
	// MARK: Songs View
	
	static let formatDidEnqueueOneSongAlertTitle = NSLocalizedString(
		"“%@” Will Play Later",
		comment: "Title of the alert that appears after the user adds one song to the queue. Include the title of the song. If the user added 2 or more songs, include “and 1 More Song”, and so on.")
	
	// MARK: - With Variables, and With Text Variations (Format Strings From Dictionaries)
	
	// MARK: Albums View
	
	static let formatChooseACollectionPrompt = NSLocalizedString(
		"choose_a_collection_prompt",
		comment: "Prompt that appears at the top of the “move albums to…” sheet. Include the number of albums you’re moving.")
	
	// MARK: Songs View
	
	static let formatDidEnqueueMultipleSongsAlertTitle = NSLocalizedString(
		"did_enqueue_multiple_songs_alert_title",
		comment: "Title of the alert that appears after the user adds multiple songs to the queue. Include the title of the song. Also, if the user added 2 songs, include “and 1 More Song”, and if they added 3 songs, include “and 2 More Songs”, and so on.")
	
}
