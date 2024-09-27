import Foundation

// Reference user-facing text here to keep it consistent throughout the app.
enum InterfaceText {
	// Don’t pass arguments other than strings to the Foundation function `NSLocalizedString`, because otherwise, when you choose “Export Localizations…”, Xcode won’t include those calls.
	
	// MARK: - WITHOUT VARIABLES
	
	// MARK: General
	
	static let cancel = NSLocalizedString("Cancel", comment: "Button")
	static let done = NSLocalizedString("Done", comment: "Button")
	static let more = NSLocalizedString("More", comment: "Button")
	
	static let interpunct = NSLocalizedString("·", comment: "Interpunct, for separating pieces of information")
	static let octothorpe = NSLocalizedString("#", comment: "Number sign. Stand-in for missing number")
	static let emDash = NSLocalizedString("—", comment: "Em dash. Stand-in for missing general text: song titles, album titles, album artists, etc.")
	static let tilde = NSLocalizedString("~", comment: "Invisible, but here for consistency. Default title for a new crate, which used to contain albums.")
	
	static let unknownArtist = NSLocalizedString("Unknown Artist", comment: "Stand-in for missing info on albums and songs")
	static let unknownAlbum = NSLocalizedString("Unknown Album", comment: "Stand-in for missing album title")
	static let albumArtwork = NSLocalizedString("Album artwork", comment: "Accessibility label")
	static let nowPlaying = NSLocalizedString("Now Playing", comment: "Button and accessibility label")
	static let paused = NSLocalizedString("Paused", comment: "Accessibility label")
	static let appleMusic = NSLocalizedString("Apple Music", comment: "Button")
	
	static let welcome_message = NSLocalizedString("SongPocket shows and plays your Apple Music library.", comment: "Placeholder when no access to Apple Music; subtitle")
	static let welcome_button = NSLocalizedString("Continue", comment: "Button")
	static let _emptyLibraryMessage = NSLocalizedString("Add music to your Apple Music library.", comment: "Message in menu when database is empty")
	
	// MARK: Playback
	
	static let startPlaying = NSLocalizedString("Start Playing", comment: "Button")
	static let addToQueue = NSLocalizedString("Add to Queue", comment: "Button")
	static let addRestOfAlbumToQueue = NSLocalizedString("Add Rest of Album to Queue", comment: "Button")
	
	static let play = NSLocalizedString("Play", comment: "Button")
	static let pause = NSLocalizedString("Pause", comment: "Button")
	static let skipBack15Seconds = NSLocalizedString("Skip back 15 seconds", comment: "Button") // As of iOS 16.5 RC 1, picture-in-picture videos use “Skip back 10 seconds” and “Skip forward 10 seconds”.
	static let skipForward15Seconds = NSLocalizedString("Skip forward 15 seconds", comment: "Button")
	
	static let previous = NSLocalizedString("Previous", comment: "Button")
	static let restart = NSLocalizedString("Restart", comment: "Button")
	static let next = NSLocalizedString("Next", comment: "Button")
	
	static let shuffle = NSLocalizedString("Shuffle", comment: "Button")
	static let repeat1 = NSLocalizedString("Repeat One", comment: "Button")
	
	// MARK: Editing
	
	static let select = NSLocalizedString("Select", comment: "Button")
	static let selected = NSLocalizedString("Selected", comment: "Accessibility label")
	static let selectUp = NSLocalizedString("Select Up", comment: "Button")
	static let selectDown = NSLocalizedString("Select Down", comment: "Button")
	static let deselectUp = NSLocalizedString("Deselect Up", comment: "Button")
	static let deselectDown = NSLocalizedString("Deselect Down", comment: "Button")
	
	static let sort = NSLocalizedString("Sort", comment: "Button")
	static let recentlyAdded = NSLocalizedString("Recently Added", comment: "Sort option")
	static let recentlyReleased = NSLocalizedString("Recently Released", comment: "Sort option")
	static let artist = NSLocalizedString("Artist", comment: "Sort option")
	static let title = NSLocalizedString("Title", comment: "Sort option. The word for the name of an album.")
	static let trackNumber = NSLocalizedString("Track Number", comment: "Sort option")
	static let random = NSLocalizedString("Random", comment: "Sort option")
	static let reverse = NSLocalizedString("Reverse", comment: "Sort option")
	
	static let moveUp = NSLocalizedString("Move up", comment: "Accessibility label")
	static let moveDown = NSLocalizedString("Move down", comment: "Accessibility label")
	static let toTop = NSLocalizedString("To Top", comment: "Button")
	static let toBottom = NSLocalizedString("To Bottom", comment: "Button")
	
	// MARK: - WITH VARIABLES, BUT NO TEXT VARIATIONS
	
	// MARK: - WITH VARIABLES AND TEXT VARIATIONS
	// (Format strings from dictionaries)
}
