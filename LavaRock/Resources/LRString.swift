//
//  LRString.swift
//  LavaRock
//
//  Created by h on 2020-12-05.
//

import Foundation

// Keeping these keys in one place helps us keep them unique.
// It also helps us use the same text in multiple places if appropriate.
enum LRString {
	// Don’t pass arguments other than strings to the Foundation function `NSLocalizedString`, because otherwise, when you choose “Export Localizations…”, Xcode won’t include those calls.
	
	// MARK: - Without variables
	
	// MARK: Standard
	
	static let cancel = NSLocalizedString("Cancel", comment: "Button")
	static let save = NSLocalizedString("Save", comment: "Button")
	static let done = NSLocalizedString("Done", comment: "Button")
	static let more = NSLocalizedString("More", comment: "Button")
	
	static let ellipsis = NSLocalizedString("…", comment: "Indicator for truncated text")
	static let interpunct = NSLocalizedString("·", comment: "Interpunct, for separating pieces of information")
	
	static let loadingEllipsis = NSLocalizedString("Loading…", comment: "Status message")
	
	// MARK: Albums
	
	static let unknownAlbum = NSLocalizedString("Unknown Album", comment: "")
	static let unknownAlbumArtist = NSLocalizedString("Unknown Album Artist", comment: "")
	
	// MARK: Settings
	
	static let settings = NSLocalizedString("Settings", comment: "Button")
	
	static let theme = NSLocalizedString("Theme", comment: "Section header")
	
	static let light = NSLocalizedString("Light", comment: "Accessibility label, appearance option")
	static let dark = NSLocalizedString("Dark", comment: "Accessibility label, appearance option")
	static let system = NSLocalizedString("System", comment: "Accessibility label, appearance option")
	
	static let lime = NSLocalizedString("Lime", comment: "Accent color")
	static let tangerine = NSLocalizedString("Tangerine", comment: "Accent color")
	static let strawberry = NSLocalizedString("Strawberry", comment: "Accent color")
	static let grape = NSLocalizedString("Grape", comment: "Accent color")
	static let blueberry = NSLocalizedString("Blueberry", comment: "Accent color")
	
	static let nowPlayingIcon = NSLocalizedString("Now-Playing Icon", comment: "Section header")
	
	static let speaker = NSLocalizedString("Speaker", comment: "Accessibility label")
	static let pawprint = NSLocalizedString("Pawprint", comment: "Accessibility label")
	static let fish = NSLocalizedString("Fish", comment: "Accessibility label")
	static let luxoLamp = NSLocalizedString("Luxo lamp", comment: "Accessibility label")
	
	static let tipJar = NSLocalizedString("Tip Jar", comment: "Section header")
	
	static let reload = NSLocalizedString("Reload", comment: "Button")
	static let confirmingEllipsis = NSLocalizedString("Confirming…", comment: "Status message")
	static let tipJarFooter = NSLocalizedString(
		"Thank you for using Songpocket.",
		comment: "Section footer")
	static let tipThankYouMessageWithPaddingSpaces = NSLocalizedString(
		" Thank You! ",
		comment: "After leaving a tip, the thank-you message that appears between two heart emojis. Include padding spaces if your language uses them.")
	
	// MARK: Transport bar
	
	static let appleMusic = NSLocalizedString("Apple Music", comment: "Button")
	
	static let previous = NSLocalizedString("Previous", comment: "Button")
	static let restart = NSLocalizedString("Restart", comment: "Button")
	// As of iOS 16.5 RC 1, picture-in-picture videos use “Skip back 10 seconds” and “Skip forward 10 seconds”.
	static let skipBack10Seconds = NSLocalizedString("Skip back 10 seconds", comment: "Accessibility label, button")
	static let play = NSLocalizedString("Play", comment: "Accessibility label, button")
	static let pause = NSLocalizedString("Pause", comment: "Accessibility label, button")
	static let skipForward10Seconds = NSLocalizedString("Skip forward 10 seconds", comment: "Accessibility label, button")
	static let next = NSLocalizedString("Next", comment: "Button")
	
	// MARK: Now-playing marker
	
	static let nowPlaying = NSLocalizedString("Now playing", comment: "Accessibility label")
	static let paused = NSLocalizedString("Paused", comment: "Accessibility label")
	
	// MARK: Editing
	
	static let arrange = NSLocalizedString("Arrange", comment: "Button")
	static let recentlyAdded = NSLocalizedString("Recently Added", comment: "Sort option")
	static let random = NSLocalizedString("Random", comment: "Sort option")
	static let reverse = NSLocalizedString("Reverse", comment: "Sort option")
	
	static let moveToTop = NSLocalizedString("Move to top", comment: "Accessibility label, button")
	static let moveToBottom = NSLocalizedString("Move to bottom", comment: "Accessibility label, button")
	
	// MARK: Folders view
	
	static let folders = NSLocalizedString("Folders", comment: "Big title")
	
	static let allowAccessToMusic = NSLocalizedString("Allow Access to Apple Music", comment: "Button")
	static let emptyDatabasePlaceholder = NSLocalizedString(
		"Add some music to your library.",
		comment: "Placeholder for when the app’s database is empty")
	
	static let name = NSLocalizedString("Name", comment: "The word for the title of a folder. Also a sort option.")
	
	static let rename = NSLocalizedString("Rename", comment: "Button")
	static let renameFolder = NSLocalizedString("Rename Folder", comment: "Alert title")
	
	static let combine = NSLocalizedString("Combine", comment: "Button")
	
	static let newFolder = NSLocalizedString("New Folder", comment: "Button")
	static let untitledFolder = NSLocalizedString(
		"Untitled Folder",
		comment: "Default title for a folder if you create one and don’t provide a title.")
	
	// MARK: Albums view
	
	static let noAlbums = NSLocalizedString("No Albums", comment: "Placeholder when showing an empty folder")
	
	static let move = NSLocalizedString("Move", comment: "Button")
	static let byAlbumArtistEllipsis = NSLocalizedString("By Album Artist…", comment: "Menu option")
	static let toFolderEllipsis = NSLocalizedString("To Folder…", comment: "Menu option")
	
	static let recentlyReleased = NSLocalizedString("Recently Released", comment: "Sort option")
	
	static let moveHere = NSLocalizedString("Move Here", comment: "Button")
	
	// MARK: Songs view
	
	static let noSongs = NSLocalizedString("No Songs", comment: "Placeholder when showing an empty album")
	
	static let albumArtwork = NSLocalizedString("Album artwork", comment: "Accessibility label")
	
	static let startPlaying = NSLocalizedString("Start Playing", comment: "Button")
	
	static let playNext = NSLocalizedString("Play Next", comment: "Button")
	static let playLast = NSLocalizedString("Play Last", comment: "Button")
	static let playRestOfAlbumNext = NSLocalizedString("Play Rest of Album Next", comment: "Button")
	static let playRestOfAlbumLast = NSLocalizedString("Play Rest of Album Last", comment: "Button")
	
	static let trackNumber = NSLocalizedString("Track Number", comment: "Sort option")
	
	// MARK: Console
	
	static let queue = NSLocalizedString("Queue", comment: "Big title")
	
	static let repeat1 = NSLocalizedString("Repeat One", comment: "Button")
	static let repeatAll = NSLocalizedString("Repeat All", comment: "Button")
	static let repeatOff = NSLocalizedString("Repeat Off", comment: "Button")
	
	// MARK: - With variables but without text variations (format strings)
	
	// MARK: Songs view
	
	static let format_quoted = NSLocalizedString(
		"“%@”",
		comment: "The input string, wrapped in quotation marks.")
	
	// MARK: - With variables and text variations (format strings from dictionaries)
	
	// MARK: Folders and Albums views
	
	static let variable_moveXAlbumsToYFoldersByAlbumArtistQuestionMark = NSLocalizedString(
		"plural - move_X_albums_to_Y_folders_by_album_artist_question_mark",
		comment: "Prompt that appears atop the “organize albums” sheet. Include the number of albums the app is moving, and the number of folders it’s moving them into.")
	static let variable_moveXAlbumsTo = NSLocalizedString(
		"plural - move_X_albums_to",
		comment: "Prompt that appears atop the “move albums” sheet. Include the number of albums the user is moving.")
	
	// MARK: Albums view
	
	static let variable_moveXAlbumsIntoOneFolder_question_mark = NSLocalizedString(
		"plural - move_X_albums_into_one_folder_question_mark",
		comment: "Prompt that appears atop the “Combine” sheet. Include the number of albums the app is moving into the newly created folder.")
	
	// MARK: Songs view
	
	static func songTitleQuotedAndXMoreSongs_titleCase(
		infos: [SongInfo]
	) -> String {
		let firstTitle = infos.first?.titleOnDisk ?? SongInfoPlaceholder.unknownTitle
		let count = infos.count
		if count == 1 {
			return String.localizedStringWithFormat(
				format_quoted,
				firstTitle)
		} else {
			// With “and X more”
			return String.localizedStringWithFormat(
				format_title_songTitleAndXMoreSongs,
				firstTitle,
				count - 1)
		}
	}
	static let format_title_songTitleAndXMoreSongs = NSLocalizedString(
		"plural - title case - SONG_TITLE_and_X_more_songs",
		comment: "The title of a song, wrapped in quotation marks, plus “and 1 More Song”, “and 2 More Songs”, or so on.")
}
