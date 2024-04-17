// 2020-12-05

import Foundation

enum LRString {
	// Don’t pass arguments other than strings to the Foundation function `NSLocalizedString`, because otherwise, when you choose “Export Localizations…”, Xcode won’t include those calls.
	
	// MARK: - WITHOUT VARIABLES
	
	static let cancel = NSLocalizedString("Cancel", comment: "Button")
	static let more = NSLocalizedString("More", comment: "Button")
	
	static let interpunct = NSLocalizedString("·", comment: "Interpunct, for separating pieces of information")
	static let tilde = NSLocalizedString("~", comment: "Default title for a new folder")
	static let octothorpe = NSLocalizedString("#", comment: "Number sign, for missing number")
	static let emDash = NSLocalizedString("—", comment: "Em dash, for missing data")
	
	static let unknownArtist = NSLocalizedString("Unknown Artist", comment: "")
	static let unknownAlbum = NSLocalizedString("Unknown Album", comment: "")
	
	static let nowPlaying = NSLocalizedString("Now playing", comment: "Accessibility label")
	static let paused = NSLocalizedString("Paused", comment: "Accessibility label")
	
	// MARK: Toolbar
	
	static let previous = NSLocalizedString("Previous", comment: "Button")
	static let restart = NSLocalizedString("Restart", comment: "Button")
	// As of iOS 16.5 RC 1, picture-in-picture videos use “Skip back 10 seconds” and “Skip forward 10 seconds”.
	static let skipBack15Seconds = NSLocalizedString("Skip back 15 seconds", comment: "Button")
	static let play = NSLocalizedString("Play", comment: "Button")
	static let pause = NSLocalizedString("Pause", comment: "Button")
	static let skipForward15Seconds = NSLocalizedString("Skip forward 15 seconds", comment: "Button")
	static let next = NSLocalizedString("Next", comment: "Button")
	
	static let repeatOff = NSLocalizedString("Repeat Off", comment: "Button")
	static let repeat1 = NSLocalizedString("Repeat One", comment: "Button")
	
	static let sort = NSLocalizedString("Sort", comment: "Button")
	static let random = NSLocalizedString("Random", comment: "Sort option")
	static let reverse = NSLocalizedString("Reverse", comment: "Sort option")
	static let moveToTop = NSLocalizedString("Move to top", comment: "Accessibility label, button")
	static let moveToBottom = NSLocalizedString("Move to bottom", comment: "Accessibility label, button")
	
	// MARK: Albums view
	
	static let welcome_message = NSLocalizedString("SongPocket views and plays your Apple Music library.", comment: "Placeholder when no access to Apple Music; subtitle")
	static let welcome_button = NSLocalizedString("Continue", comment: "Button")
	
	static let emptyLibrary_button = NSLocalizedString("Add Music to Library", comment: "Button")
	
	static let albumArtwork = NSLocalizedString("Album artwork", comment: "Accessibility label")
	
	static let recentlyReleased = NSLocalizedString("Recently Released", comment: "Sort option")
	static let oldest = NSLocalizedString("Oldest", comment: "Sort option")
	static let artist = NSLocalizedString("Artist", comment: "Sort option")
	
	// MARK: Songs view
	
	static let startPlaying = NSLocalizedString("Start Playing", comment: "Button")
	static let playLast = NSLocalizedString("Play Last", comment: "Button")
	static let playRestOfAlbumLast = NSLocalizedString("Play Rest of Album Last", comment: "Button")
	
	static let trackNumber = NSLocalizedString("Track Number", comment: "Sort option")
	
	// MARK: - WITH VARIABLES, BUT NO TEXT VARIATIONS
	
	// MARK: - WITH VARIABLES AND TEXT VARIATIONS
	// (Format strings from dictionaries)
}
