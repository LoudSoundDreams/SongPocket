//
//  LRString.swift
//  LavaRock
//
//  Created by h on 2020-12-05.
//

import Foundation
import MediaPlayer

// Putting all the keys we pass to `NSLocalizedString` in one place (here) helps us keep them unique, which we must do to ensure predictable behavior.
// It also helps us use the same phrases in multiple places if appropriate.
struct LRString {
	private init() {}
	
	// Don’t pass arguments other than strings to the Foundation function `NSLocalizedString`, because otherwise, when you choose “Export Localizations…”, Xcode won’t include those calls.
	
	// MARK: - Without Variables
	
	// MARK: Standard
	
	static let cancel = NSLocalizedString("Cancel", comment: "Button")
	static let save = NSLocalizedString("Save", comment: "Button")
	static let done = NSLocalizedString("Done", comment: "Button")
	static let ok = NSLocalizedString("OK", comment: "Button")
	static let more = NSLocalizedString("More", comment: "Button")
	
	static let ellipsis = NSLocalizedString("…", comment: "Indicator for truncated text")
	static let interpunct = NSLocalizedString("·", comment: "Separator between pieces of information")
	
	static let loadingEllipsis = NSLocalizedString("Loading…", comment: "Status message")
	
	// MARK: Albums
	
	static let unknownAlbum = NSLocalizedString("Unknown Album", comment: "")
	static let unknownAlbumArtist = NSLocalizedString("Unknown Album Artist", comment: "")
	
	// MARK: Songs
	
	static let unknownArtist = NSLocalizedString("Unknown Artist", comment: "")
	
	// MARK: Options
	
	static let options = Enabling.iconsInNavigationBar
	? NSLocalizedString("Settings", comment: "Big title")
	: NSLocalizedString("Options", comment: "Big title")
	
	static let theme = NSLocalizedString("Theme", comment: "Section header")
	
	static let light = NSLocalizedString("Light", comment: "Appearance option")
	static let dark = NSLocalizedString("Dark", comment: "Appearance option")
	static let system = NSLocalizedString("System", comment: "Appearance option")
	
	static let accentColor = NSLocalizedString("Accent Color", comment: "Section header")
	static let strawberry = NSLocalizedString("Strawberry", comment: "Accent color")
	static let tangerine = NSLocalizedString("Tangerine", comment: "Accent color")
	static let lime = NSLocalizedString("Lime", comment: "Accent color")
	static let blueberry = NSLocalizedString("Blueberry", comment: "Accent color")
	static let grape = NSLocalizedString("Grape", comment: "Accent color")
	
	static let avatar = NSLocalizedString("Now-Playing Icon", comment: "Section header")
	
	static let tipJar = NSLocalizedString("Tip Jar", comment: "Section header")
	static let reload = NSLocalizedString("Reload", comment: "Button")
	static let confirmingEllipsis = NSLocalizedString("Confirming…", comment: "Status message")
	static let tipJarFooter = NSLocalizedString(
		"Songpocket • made with love",
		comment: "Section footer")
	static let tipThankYouMessageWithPaddingSpaces = NSLocalizedString(" Thank You! ", comment: "After leaving a tip, the thank-you message that appears between two heart emojis. Include padding spaces if your language uses them.")
	
	// MARK: Transport Bar
	
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
	static let random = NSLocalizedString("Random", comment: "Sort option")
	static let reverse = NSLocalizedString("Reverse", comment: "Sort option")
	
	static let moveToTop = NSLocalizedString("Move to top", comment: "Accessibility label, button")
	static let moveToBottom = NSLocalizedString("Move to bottom", comment: "Accessibility label, button")
	
	// MARK: Collections View
	
	static let collections = NSLocalizedString("Folders", comment: "Big title")
	
	static let allowAccessToMusic = NSLocalizedString("Allow Access to Music", comment: "Button")
	static let emptyDatabasePlaceholder = NSLocalizedString(
		"Add music to your library from Apple Music, your computer, or the iTunes Store.",
		comment: "Placeholder for when the app’s database is empty")
	static let openMusic = NSLocalizedString("Open Music", comment: "Button")
	
	static let title = NSLocalizedString("Title", comment: "The word for the name of a collection, album, or song. Also the name of a sort option.")
	
	static let rename = NSLocalizedString("Rename", comment: "Button")
	static let renameCollectionAlertTitle = NSLocalizedString("Rename Folder", comment: "Alert title")
	
	static let combine = NSLocalizedString("Combine", comment: "Button")
	static let combineCollectionsAlertTitle = NSLocalizedString("Combine Folders", comment: "Alert title")
	static let combinedCollectionDefaultTitle = NSLocalizedString("Combined Folder", comment: "Alert title")
	
	static let newCollection_buttonTitle = NSLocalizedString(
		"New Collection [button]",
		value: "New Folder",
		comment: "Button") // MC2DO: Obviate
	static let newCollection_alertTitle = NSLocalizedString(
		"New Collection [alert title]",
		value: "New Folder",
		comment: "Alert title") // MC2DO: Obviate
	static let newCollection_defaultTitle = NSLocalizedString(
		"New Collection [default title for collection]",
		value: "New Folder",
		comment: "Default title for a collection if you create one and don’t provide a title.")
	
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
	
	static let playRestOfAlbum = NSLocalizedString("Play Song and Below", comment: "Button")
	static let playSong = NSLocalizedString("Play Song", comment: "Button")
	
	static let insertSong = NSLocalizedString("Insert Song", comment: "Button")
	static let insertRestOfAlbum = NSLocalizedString("Insert Song and Below", comment: "Button")
	
	static let queueSong = NSLocalizedString("Queue Song", comment: "Button")
	static let queueRestOfAlbum = NSLocalizedString("Queue Song and Below", comment: "Button")
	
	static let trackNumber = NSLocalizedString("Track Number", comment: "Sort option")
	
	// MARK: Console
	
	static let clear = NSLocalizedString("Clear", comment: "Button")
	
	static let queue = NSLocalizedString("Queue", comment: "Big title")
	
	static let repeat1 = NSLocalizedString("Repeat one", comment: "Accessibility label")
	static let repeatAll = NSLocalizedString("Repeat all", comment: "Accessibility label")
	static let repeatOff = NSLocalizedString("Repeat off", comment: "Accessibility label")
	
	// MARK: - With Variables, but Without Text Variations (Format Strings)
	
	// MARK: Songs View
	
	static let format_quoted = NSLocalizedString(
		"“%@”",
		comment: "The input string, wrapped in quotation marks.")
	
	// MARK: - With Variables, and With Text Variations (Format Strings From Dictionaries)
	
	// MARK: Collections
	
	static let format_xCollections = NSLocalizedString(
		"plural - X_collections",
		comment: "Status message")
	
	// MARK: Albums
	
	static let format_xAlbums = NSLocalizedString(
		"plural - X_albums",
		comment: "Status message")
	
	// MARK: Songs
	
	static let format_xSongs = NSLocalizedString(
		"plural - X_songs",
		comment: "Status message")
	
	// MARK: Collections and Albums Views
	
	static let format_organizeIntoXCollectionsByAlbumArtistQuestionMark = NSLocalizedString(
		"plural - organize_into_X_collections_by_album_artist",
		comment: "Prompt that appears atop the “organize albums” sheet. Include the number of albums the app is moving, and the number of collections it’s moving them into.")
	static let format_chooseACollectionToMoveXAlbumsTo = NSLocalizedString(
		"plural - move_albums_to_collection",
		comment: "Prompt that appears atop the “move albums” sheet. Include the number of albums the user is moving.")
	
	// MARK: Songs View
	
	static func songTitleQuotedAndXMoreSongs_titleCase(
		mediaItems: [MPMediaItem]
	) -> String {
		let firstSongTitle = mediaItems.first?.titleOnDisk ?? SongMetadatumPlaceholder.unknownTitle
		let songCount = mediaItems.count
		if songCount == 1 {
			return String.localizedStringWithFormat(
				format_quoted,
				firstSongTitle)
		} else {
			// With “and X more”
			return String.localizedStringWithFormat(
				format_title_songTitleAndXMoreSongs,
				firstSongTitle,
				songCount - 1)
		}
	}
	static let format_title_songTitleAndXMoreSongs = NSLocalizedString(
		"plural - title case - SONG_TITLE_and_X_more_songs",
		comment: "The title of a song, wrapped in quotation marks, plus “and 1 More Song”, “and 2 More Songs”, or so on.")
}
