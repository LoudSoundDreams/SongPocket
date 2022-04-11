//
//  LocalizedString.swift
//  LavaRock
//
//  Created by h on 2020-12-05.
//

import Foundation

// Putting all the keys we pass to NSLocalizedString in one place (here) helps us keep them unique, which we must do to ensure predictable behavior.
// It also helps us use the same phrases in multiple places if appropriate.
struct LocalizedString {
	private init() {}
	
	// Don’t pass arguments to the Foundation function `NSLocalizedString`, because when you choose Editor -> Export for Localization…, Xcode won’t include those calls.
	
	// MARK: - Without Variables
	
	// MARK: Standard
	
	static let cancel = NSLocalizedString("Cancel", comment: "Button")
	static let save = NSLocalizedString("Save", comment: "Button")
	static let done = NSLocalizedString("Done", comment: "Button")
	static let ok = NSLocalizedString("OK", comment: "Button")
	
	static let ellipsis = NSLocalizedString("…", comment: "Indicator for truncated text")
	
	static let loadingEllipsis = NSLocalizedString("Loading…", comment: "")
	
	// MARK: Albums
	
	static let unknownAlbum = NSLocalizedString("Unknown Album", comment: "")
	static let unknownAlbumArtist = NSLocalizedString("Unknown Album Artist", comment: "")
	
	// MARK: Options
	
	static let options = NSLocalizedString("Options", comment: "Big title")
	
	static let theme = NSLocalizedString("Theme", comment: "Section header")
	
	static let light = NSLocalizedString("Light", comment: "Appearance option")
	static let dark = NSLocalizedString("Dark", comment: "Appearance option")
	static let system = NSLocalizedString("System", comment: "Appearance option")
	
	static let strawberry = NSLocalizedString("Strawberry", comment: "Accent color")
	static let tangerine = NSLocalizedString("Tangerine", comment: "Accent color")
	static let lime = NSLocalizedString("Lime", comment: "Accent color")
	static let blueberry = NSLocalizedString("Blueberry", comment: "Accent color")
	static let grape = NSLocalizedString("Grape", comment: "Accent color")
	
	static let tipJar = NSLocalizedString("Tip Jar", comment: "Section header")
	static let reload = NSLocalizedString("Reload", comment: "Button")
	static let confirmingEllipsis = NSLocalizedString("Confirming…", comment: "")
	static let tipJarFooter = NSLocalizedString(
		"[footer] options_tip_jar",
		value: "a Loud Sound Dreams production",
		comment: "Section footer")
	static let tipThankYouMessageWithPaddingSpaces = NSLocalizedString(" Thank You! ", comment: "After leaving a tip, the thank-you message that appears between two heart emojis. Include padding spaces if your language uses them.")
	
	// MARK: Playback Toolbar
	
	static let previousTrack = NSLocalizedString("Previous track", comment: "Accessibility label, button")
	static let restart = NSLocalizedString("Restart", comment: "Accessibility label, button")
	static let skip10SecondsBackwards = NSLocalizedString("Skip 10 seconds backwards", comment: "Accessibility label, button")
	static let play = NSLocalizedString("Play", comment: "Accessibility label, button")
	static let pause = NSLocalizedString("Pause", comment: "Accessibility label, button")
	static let skip10SecondsForward = NSLocalizedString("Skip 10 seconds forward", comment: "Accessibility label, button")
	static let nextTrack = NSLocalizedString("Next track", comment: "Accessibility label, button")
	
	// MARK: “Now Playing” Indicator
	
	static let nowPlaying = NSLocalizedString("Now playing", comment: "Accessibility label")
	static let paused = NSLocalizedString("Paused", comment: "Accessibility label")
	
	// MARK: Editing
	
	static let sort = NSLocalizedString("Sort", comment: "Button")
	static let shuffle = NSLocalizedString("Shuffle", comment: "Sort option")
	static let reverse = NSLocalizedString("Reverse", comment: "Sort option")
	
	static let moveToTop = NSLocalizedString("Move to top", comment: "Accessibility label, button")
	static let moveToBottom = NSLocalizedString("Move to bottom", comment: "Accessibility label, button")
	
	// MARK: Collections View // MC2DO: Edit
	
	static let sections = NSLocalizedString("Sections", comment: "Big title")
	static let collections = NSLocalizedString("Collections", comment: "Big title") // MC2DO: Delete
	
	static let allowAccessToMusic = NSLocalizedString("Allow Access to Music", comment: "Button")
	static let emptyDatabasePlaceholder = NSLocalizedString(
		"[placeholder] empty_database",
		value: "Add music to your library from Apple Music, your computer, or the iTunes Store.",
		comment: "Placeholder for when the app’s database is empty")
	static let openMusic = NSLocalizedString("Open Music", comment: "Button")
	
	static let title = NSLocalizedString("Title", comment: "The word for the name of a collection, album, or song. Also the name of a sort option.") // MC2DO: Edit
	
	static let rename = NSLocalizedString("Rename", comment: "Button")
	static let renameSectionAlertTitle = NSLocalizedString("Rename Section", comment: "Alert title")
	static let renameCollectionAlertTitle = NSLocalizedString("Rename Collection", comment: "Alert title") // MC2DO: Delete
	
	static let combine = NSLocalizedString("Combine", comment: "Button")
	static let combineSectionsAlertTitle = NSLocalizedString("Combine Sections", comment: "Alert title")
	static let combineCollectionsAlertTitle = NSLocalizedString("Combine Collections", comment: "Alert title") // MC2DO: Delete
	static let combinedSectionDefaultTitle = NSLocalizedString("Combined Section", comment: "Alert title")
	static let combinedCollectionDefaultTitle = NSLocalizedString("Combined Collection", comment: "Alert title") // MC2DO: Delete
	
	static let newSectionButtonTitle = NSLocalizedString(
		"New Section [button]",
		value: "New Section",
		comment: "Button") // MC2DO: Obviate
	static let newSectionAlertTitle = NSLocalizedString(
		"New Section [alert title]",
		value: "New Section",
		comment: "Alert title")
	static let newCollectionAlertTitle = NSLocalizedString(
		"New Collection [alert title]",
		value: "New Collection",
		comment: "Alert title") // MC2DO: Delete
	static let newSectionDefaultTitle = NSLocalizedString(
		"New Section [default title for section]",
		value: "New Section",
		comment: "Default title for a section if you create one and don’t provide a title.")
	static let newCollectionDefaultTitle = NSLocalizedString(
		"New Collection [default title for collection]",
		value: "New Collection",
		comment: "Default title for a collection if you create one and don’t provide a title.") // MC2DO: Delete
	
	// MARK: Albums View
	
	static let albums = NSLocalizedString("Albums", comment: "Big title")
	
	static let move = NSLocalizedString("Move", comment: "Button")
	static let organizeByAlbumArtistEllipsis = NSLocalizedString("Organize by Album Artist…", comment: "Menu option")
	static let moveToEllipsis = NSLocalizedString("Move To…", comment: "Menu option")
	
	static let newest = NSLocalizedString("Newest", comment: "Sort option")
	static let oldest = NSLocalizedString("Oldest", comment: "Sort option")
	
	static let moveHere = NSLocalizedString("Move Here", comment: "Button")
	
	// MARK: Songs View
	
	static let songs = NSLocalizedString("Songs", comment: "Big title")
	
	static let albumArtwork = NSLocalizedString("Album artwork", comment: "Accessibility label")
	static let playSongAndBelow = NSLocalizedString("Play Song and Below", comment: "Button")
	static let queueSongAndBelow = NSLocalizedString("Queue Song and Below", comment: "Button")
	static let playSong = NSLocalizedString("Play Song", comment: "Button")
	static let queueSong = NSLocalizedString("Queue Song", comment: "Button")
	static let didEnqueueSongsAlertMessage = NSLocalizedString(
		"[alert message] did_enqueue_songs",
		value: "Open Music to edit the queue.",
		comment: "Body text of the alert that appears after the user adds songs to the queue.")
	static let dontShowAgain = NSLocalizedString("Don’t Show Again", comment: "Button")
	static let trackNumber = NSLocalizedString("Track Number", comment: "Sort option")
	
	// MARK: Player Screen
	
	static let repeat1 = NSLocalizedString("Repeat one", comment: "Accessibility label")
	static let repeatAll = NSLocalizedString("Repeat all", comment: "Accessibility label")
	static let repeatOff = NSLocalizedString("Repeat off", comment: "Accessibility label")
	
	// MARK: - With Variables, but Without Text Variations (Format Strings)
	
	// MARK: Songs View
	
	static let format_didEnqueueOneSongAlertTitle = NSLocalizedString(
		"[alert title] did_enqueue_one_song",
		value: "“%@” Will Play Later",
		comment: "Title of the alert that appears after the user adds one song to the queue. Include the title of the song. If the user added 2 or more songs, include “and 1 More Song”, and so on.")
	
	// MARK: - With Variables, and With Text Variations (Format Strings From Dictionaries)
	
	// MARK: Collections and Albums Views // MC2DO: Edit
	
	static let format_organizeIntoXSectionsByAlbumArtistQuestionMark = NSLocalizedString(
		"plural - organize_into_X_sections_by_album_artist",
		comment: "Prompt that appears at the top of the “organize albums” sheet. Include the number of sections the app is moving the albums into.")
	static let format_organizeIntoXCollectionsByAlbumArtistQuestionMark = NSLocalizedString(
		"plural - organize_into_X_collections_by_album_artist",
		comment: "Prompt that appears at the top of the “organize albums” sheet. Include the number of collections the app is moving the albums into.") // MC2DO: Delete
	
	static let format_chooseASectiontoMoveXAlbumsTo = NSLocalizedString(
		"plural - move_albums_to_section",
		comment: "Prompt that appears at the top of the “move albums” sheet. Include the number of albums you’re moving.")
	static let format_chooseACollectionToMoveXAlbumsTo = NSLocalizedString(
		"plural - move_albums_to_collection",
		comment: "Prompt that appears at the top of the “move albums” sheet. Include the number of albums you’re moving.") // MC2DO: Delete
	
	// MARK: Songs View
	
	static let format_didEnqueueMultipleSongsAlertTitle = NSLocalizedString(
		"plural - did_enqueue_multiple_songs",
		comment: "Title of the alert that appears after the user adds multiple songs to the queue. Include the title of the song. Also, if the user added 2 songs, include “and 1 More Song”, and if they added 3 songs, include “and 2 More Songs”, and so on.")
}
