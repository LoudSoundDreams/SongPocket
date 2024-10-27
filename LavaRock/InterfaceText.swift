// For consistency throughout the app.

enum InterfaceText {
	// MARK: - General
	
	static let cancel = "Cancel"
	static let continue_ = "Continue"
	static let done = "Done"
	static let more = "More"
	
	static let _interpunct = "·"
	static let _octothorpe = "#"
	static let _emDash = "—"
	static let _tilde = "~"
	
	static let unknownArtist = "Unknown Artist"
	static let unknownAlbum = "Unknown Album"
	static let albumArtwork = "Album artwork"
	static let nowPlaying = "Now Playing"
	static let paused = "Paused"
	static let appleMusic = "Apple Music"
	
	static let _messageWelcome = "SongPocket shows and plays your Apple Music library."
	static let _messageEmpty = "Add music to your Apple Music library."
	static func NUMBER_albumsSelected(_ num: Int) -> String {
		let fNum = num.formatted()
		if num == 1 {
			return "\(fNum) album selected"
		}
		return "\(fNum) albums selected"
	}
	static func NUMBER_albums(_ num: Int) -> String {
		let fNum = num.formatted()
		if num == 1 {
			return "\(fNum) album"
		}
		return "\(fNum) albums"
	}
	static func NUMBER_songsSelected(_ num: Int) -> String {
		let fNum = num.formatted()
		if num == 1 {
			return "\(fNum) song selected"
		}
		return "\(fNum) songs selected"
	}
	static func NUMBER_songs(_ num: Int) -> String {
		let fNum = num.formatted()
		if num == 1 {
			return "\(fNum) song"
		}
		return "\(fNum) songs"
	}
	
	// MARK: - Playback
	
	static let startPlaying = "Start Playing"
	static let play = "Play"
	static let randomize = "Randomize"
	static let addToQueue = "Add to Queue"
	
	static let pause = "Pause"
	static let skipBack15Seconds = "Skip back 15 seconds" // As of iOS 16.5 RC 1, picture-in-picture videos use “Skip back 10 seconds” and “Skip forward 10 seconds”.
	static let skipForward15Seconds = "Skip forward 15 seconds"
	
	static let previous = "Previous"
	static let restart = "Restart"
	static let next = "Next"
	static let repeat1 = "Repeat One"
	
	// MARK: - Editing
	
	static let select = "Select"
	static let Selected = "Selected"
	static let selectRangeAbove = "Select Range Above"
	static let selectRangeBelow = "Select Range Below"
	static let deselectRangeAbove = "Deselect Range Above"
	static let deselectRangeBelow = "Deselect Range Below"
	
	static let sort = "Sort"
	static let recentlyAdded = "Recently Added"
	static let recentlyReleased = "Recently Released"
	static let trackNumber = "Track Number"
	static let shuffle = "Shuffle"
	static let reverse = "Reverse"
	
	static let moveUp = "Move up"
	static let moveDown = "Move down"
	static let toTop = "To Top"
	static let toBottom = "To Bottom"
}
