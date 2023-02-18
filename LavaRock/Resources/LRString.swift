//
//  LRString.swift
//  LavaRock
//
//  Created by h on 2020-12-05.
//

import Foundation
import MediaPlayer

// Keeping these keys in one place helps us keep them unique.
// It also helps us use the same text in multiple places if appropriate.
enum LRString {
	// Don’t pass arguments other than strings to the Foundation function `NSLocalizedString`, because otherwise, when you choose “Export Localizations…”, Xcode won’t include those calls.
	
	// MARK: - Without Variables
	
	// MARK: Standard
	
	static let cancel = NSLocalizedString("Cancel", comment: "Button")
	static let save = NSLocalizedString("Save", comment: "Button")
	static let done = NSLocalizedString("Done", comment: "Button")
	static let ok = NSLocalizedString("OK", comment: "Button")
	static let off = NSLocalizedString("Off", comment: "Button")
	static let more = NSLocalizedString("More", comment: "Button")
	
	static let ellipsis = NSLocalizedString("…", comment: "Indicator for truncated text")
	static let interpunct = NSLocalizedString("·", comment: "Interpunct, for separating pieces of information")
	
	static let loadingEllipsis = NSLocalizedString("Loading…", comment: "Status message")
	
	// MARK: Albums
	
	static let unknownAlbum = NSLocalizedString("Unknown Album", comment: "")
	static let unknownAlbumArtist = NSLocalizedString("Unknown Album Artist", comment: "")
	
	// MARK: Songs
	
	static let unknownArtist = NSLocalizedString("Unknown Artist", comment: "")
	
	// MARK: Settings
	
	static let settings = NSLocalizedString("Settings", comment: "Button")
	
	static let theme = NSLocalizedString("Theme", comment: "Section header")
	
	static let light = NSLocalizedString("Light", comment: "Accessibility label, appearance option")
	static let dark = NSLocalizedString("Dark", comment: "Accessibility label, appearance option")
	static let system = NSLocalizedString("System", comment: "Accessibility label, appearance option")
	
	static let strawberry = NSLocalizedString("Strawberry", comment: "Accent color")
	static let tangerine = NSLocalizedString("Tangerine", comment: "Accent color")
	static let lime = NSLocalizedString("Lime", comment: "Accent color")
	static let blueberry = NSLocalizedString("Blueberry", comment: "Accent color")
	static let grape = NSLocalizedString("Grape", comment: "Accent color")
	
	static let nowPlayingMarker = NSLocalizedString("Now-Playing Marker", comment: "Section header")
	
	static let speaker = NSLocalizedString("Speaker", comment: "Accessibility label")
	static let bird = NSLocalizedString("Bird", comment: "Accessibility label")
	static let fish = NSLocalizedString("Fish", comment: "Accessibility label")
	static let sailboat = NSLocalizedString("Sailboat", comment: "Accessibility label")
	static let beachUmbrella = NSLocalizedString("Beach umbrella", comment: "Accessibility label")
	
	static let tipJar = NSLocalizedString("Tip Jar", comment: "Section header")
	
	static let reload = NSLocalizedString("Reload", comment: "Button")
	static let confirmingEllipsis = NSLocalizedString("Confirming…", comment: "Status message")
	static let tipJarFooter = NSLocalizedString(
		"Consider tipping when I add features you like! Thank you for using Songpocket.",
		comment: "Section footer")
	static let tipThankYouMessageWithPaddingSpaces = NSLocalizedString(
		" Thank You! ",
		comment: "After leaving a tip, the thank-you message that appears between two heart emojis. Include padding spaces if your language uses them.")
	
	// MARK: Transport Bar
	
	static let previous = NSLocalizedString("Previous", comment: "Button")
	static let restart = NSLocalizedString("Restart", comment: "Button")
	static let skip10SecondsBackwards = NSLocalizedString("Skip 10 seconds backwards", comment: "Accessibility label, button")
	static let play = NSLocalizedString("Play", comment: "Accessibility label, button")
	static let pause = NSLocalizedString("Pause", comment: "Accessibility label, button")
	static let skip10SecondsForward = NSLocalizedString("Skip 10 seconds forward", comment: "Accessibility label, button")
	static let next = NSLocalizedString("Next", comment: "Button")
	
	// MARK: Now-Playing Marker
	
	static let nowPlaying = NSLocalizedString("Now playing", comment: "Accessibility label")
	static let paused = NSLocalizedString("Paused", comment: "Accessibility label")
	
	// MARK: Editing
	
	static let sort = NSLocalizedString("Sort", comment: "Button")
	static let random = NSLocalizedString("Random", comment: "Sort option")
	static let reverse = NSLocalizedString("Reverse", comment: "Sort option")
	
	static let moveToTop = NSLocalizedString("Move to top", comment: "Accessibility label, button")
	static let moveToBottom = NSLocalizedString("Move to bottom", comment: "Accessibility label, button")
	
	// MARK: Folders View
	
	static let folders = NSLocalizedString("Folders", comment: "Big title")
	
	static let allowAccessToMusic = NSLocalizedString("Allow Access to Music", comment: "Button")
	static let emptyDatabasePlaceholder = NSLocalizedString(
		"Add music to your library from Apple Music, your computer, or the iTunes Store.",
		comment: "Placeholder for when the app’s database is empty")
	static let openMusic = NSLocalizedString("Open Music", comment: "Button")
	
	static let title = NSLocalizedString("Title", comment: "The word for the name of a folder, album, or song. Also the name of a sort option.")
	
	static let rename = NSLocalizedString("Rename", comment: "Button")
	static let renameFolder = NSLocalizedString("Rename Folder", comment: "Alert title")
	
	static let combine = NSLocalizedString("Combine", comment: "Button")
	static let combinedFolderDefaultTitle = NSLocalizedString("Combined Folder", comment: "Alert title")
	
	static let newFolder = NSLocalizedString("New Folder", comment: "Button")
	static let untitledFolder = NSLocalizedString(
		"Untitled Folder",
		comment: "Default title for a folder if you create one and don’t provide a title.")
	
	// MARK: Albums View
	
	static let albums = NSLocalizedString("Albums", comment: "Big title")
	
	static let move = NSLocalizedString("Move", comment: "Button")
	static let byAlbumArtistEllipsis = NSLocalizedString("By Album Artist…", comment: "Menu option")
	static let toFolderEllipsis = NSLocalizedString("To Folder…", comment: "Menu option")
	
	static let newest = NSLocalizedString("Newest", comment: "Sort option")
	static let oldest = NSLocalizedString("Oldest", comment: "Sort option")
	
	static let moveHere = NSLocalizedString("Move Here", comment: "Button")
	
	// MARK: Songs View
	
	static let songs = NSLocalizedString("Songs", comment: "Big title")
	
	static let albumArtwork = NSLocalizedString("Album artwork", comment: "Accessibility label")
	
	static let playRestOfAlbum = NSLocalizedString("Play Song and Below", comment: "Button")
	static let playSong = NSLocalizedString("Play Song", comment: "Button")
	
	static let insertRestOfAlbum = NSLocalizedString("Insert Song and Below", comment: "Button")
	static let insertSong = NSLocalizedString("Insert Song", comment: "Button")
	
	static let queueRestOfAlbum = NSLocalizedString("Queue Song and Below", comment: "Button")
	static let queueSong = NSLocalizedString("Queue Song", comment: "Button")
	
	static let trackNumber = NSLocalizedString("Track Number", comment: "Sort option")
	
	// MARK: Console
	
	static let clear = NSLocalizedString("Clear", comment: "Button")
	
	static let queue = NSLocalizedString("Queue", comment: "Big title")
	
	static let repeat_Header = NSLocalizedString("Repeat", comment: "Section header")
	static let off_Repeat_mode = NSLocalizedString("Off", comment: "Repeat mode")
	static let all_Repeat_mode = NSLocalizedString("All", comment: "Repeat Mode")
	static let one_Repeat_mode = NSLocalizedString("One", comment: "Repeat mode")
	
	static let repeat1 = NSLocalizedString("Repeat One", comment: "Button")
	static let repeatAll = NSLocalizedString("Repeat All", comment: "Button")
	static let repeatOff = NSLocalizedString("Repeat Off", comment: "Button")
	
	// MARK: - With Variables, but Without Text Variations (Format Strings)
	
	// MARK: Songs View
	
	static let format_quoted = NSLocalizedString(
		"“%@”",
		comment: "The input string, wrapped in quotation marks.")
	
	// MARK: - With Variables, and With Text Variations (Format Strings From Dictionaries)
	
	// MARK: Folders
	
	static let variable_xFolders = NSLocalizedString(
		"plural - X_folders",
		comment: "Status message")
	
	// MARK: Albums
	
	static let variable_xAlbums = NSLocalizedString(
		"plural - X_albums",
		comment: "Status message")
	
	// MARK: Songs
	
	static let variable_xSongs = NSLocalizedString(
		"plural - X_songs",
		comment: "Status message")
	
	// MARK: Folders and Albums Views
	
	static let variable_moveXAlbumsToYFoldersByAlbumArtistQuestionMark = NSLocalizedString(
		"plural - move_X_albums_to_Y_folders_by_album_artist?",
		comment: "Prompt that appears atop the “organize albums” sheet. Include the number of albums the app is moving, and the number of folders it’s moving them into.")
	static let variable_chooseACollectionToMoveXAlbumsTo = NSLocalizedString(
		"plural - move_X_albums_to",
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
