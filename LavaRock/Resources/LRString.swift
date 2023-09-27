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
	
	// MARK: - WITHOUT VARIABLES
	
	// MARK: Standard
	
	static let cancel = NSLocalizedString("Cancel", comment: "Button")
	static let done = NSLocalizedString("Done", comment: "Button")
	static let more = NSLocalizedString("More", comment: "Button")
	
	static let emDash = NSLocalizedString("—", comment: "Em dash, for missing data")
	static let ellipsis = NSLocalizedString("…", comment: "Indicator for truncated text")
	static let interpunct = NSLocalizedString("·", comment: "Interpunct, for separating pieces of information")
	static let tilde = NSLocalizedString("~", comment: "Default title for a new crate")
	
	static let loadingEllipsis = NSLocalizedString("Loading…", comment: "Status message")
	
	// MARK: Albums
	
	static let unknownArtist = NSLocalizedString("Unknown Artist", comment: "")
	static let unknownAlbum = NSLocalizedString("Unknown Album", comment: "")
	
	// MARK: Toolbar
	
	static let repeat_ = NSLocalizedString("Repeat", comment: "Button")
	
	static let previous = NSLocalizedString("Previous", comment: "Button")
	static let restart = NSLocalizedString("Restart", comment: "Button")
	// As of iOS 16.5 RC 1, picture-in-picture videos use “Skip back 10 seconds” and “Skip forward 10 seconds”.
	static let skipBack15Seconds = NSLocalizedString("Skip back 15 seconds", comment: "Button")
	static let play = NSLocalizedString("Play", comment: "Button")
	static let pause = NSLocalizedString("Pause", comment: "Button")
	static let skipForward15Seconds = NSLocalizedString("Skip forward 15 seconds", comment: "Button")
	static let next = NSLocalizedString("Next", comment: "Button")
	
	// MARK: Now-playing icon
	
	static let nowPlaying = NSLocalizedString("Now playing", comment: "Accessibility label")
	static let paused = NSLocalizedString("Paused", comment: "Accessibility label")
	
	// MARK: Editing
	
	static let arrange = NSLocalizedString("Arrange", comment: "Button")
	static let random = NSLocalizedString("Random", comment: "Arrange option")
	static let reverse = NSLocalizedString("Reverse", comment: "Arrange option")
	
	static let moveToTop = NSLocalizedString("Move to top", comment: "Accessibility label, button")
	static let moveToBottom = NSLocalizedString("Move to bottom", comment: "Accessibility label, button")
	
	// MARK: - About
	
	static let about = NSLocalizedString("About", comment: "Button")
	static let sayHi = NSLocalizedString("Say Hi", comment: "Button")
	
	// MARK: - Crates view
	
	static let crates = NSLocalizedString("Crates", comment: "Big title")
	
	static let allowAccessToAppleMusic = NSLocalizedString("Allow Access to Apple Music", comment: "Button")
	static let emptyDatabasePlaceholder = NSLocalizedString(
		"Add music to your library.",
		comment: "Placeholder for when the app’s database is empty")
	static let appleMusic = NSLocalizedString("Apple Music", comment: "Button")
	
	static let name = NSLocalizedString("Name", comment: "The word for the title of a crate. Also an Arrange option.")
	
	static let rename = NSLocalizedString("Rename", comment: "Button")
	static let renameCrate = NSLocalizedString("Rename Crate", comment: "Alert title")
	
	static let combine = NSLocalizedString("Combine", comment: "Button")
	
	// MARK: Albums view
	
	static let noAlbums = NSLocalizedString("No Albums", comment: "Placeholder when showing an empty crate")
	
	static let move = NSLocalizedString("Move", comment: "Button")
	static let byArtistEllipsis = NSLocalizedString("By Artist…", comment: "Menu option")
	static let toCrateEllipsis = NSLocalizedString("To Crate…", comment: "Menu option")
	
	static let newest = NSLocalizedString("Newest", comment: "Arrange option")
	static let oldest = NSLocalizedString("Oldest", comment: "Arrange option")
	
	static let moveHere = NSLocalizedString("Move Here", comment: "Button")
	
	// MARK: Songs view
	
	static let noSongs = NSLocalizedString("No Songs", comment: "Placeholder when showing an empty album")
	
	static let albumArtwork = NSLocalizedString("Album artwork", comment: "Accessibility label")
	
	static let startPlaying = NSLocalizedString("Start Playing", comment: "Button")
	
	static let playNext = NSLocalizedString("Play Next", comment: "Button")
	static let playLast = NSLocalizedString("Play Last", comment: "Button")
	static let playRestOfAlbumNext = NSLocalizedString("Play Rest of Album Next", comment: "Button")
	static let playRestOfAlbumLast = NSLocalizedString("Play Rest of Album Last", comment: "Button")
	
	static let trackNumber = NSLocalizedString("Track Number", comment: "Arrange option")
	
	// MARK: - WITH VARIABLES AND TEXT VARIATIONS
	// (Format strings from dictionaries)
	
	// MARK: Crates and Albums views
	
	static let variable_moveXAlbumsToYCrates_questionMark = NSLocalizedString(
		"plural_Move_X_albums_to_Y_crates_questionMark",
		comment: "Prompt that appears atop the “organize albums” sheet. Include the number of albums the app is moving, and the number of crates it’s moving them into.")
	static let variable_moveXAlbumsToAnotherCrate = NSLocalizedString(
		"plural_Move_X_albums_to_another_crate",
		comment: "Prompt that appears atop the “move albums” sheet. Include the number of albums the user is moving.")
	
	// MARK: Albums view
	
	static let variable_moveXAlbumsIntoOneCrate_questionMark = NSLocalizedString(
		"plural_Move_X_albums_into_one_crate_questionMark",
		comment: "Prompt that appears atop the “Combine” sheet. Include the number of albums the app is moving into the newly created crate.")
}
