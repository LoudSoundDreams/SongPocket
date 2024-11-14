// For consistency throughout the app.

import Foundation
enum InterfaceText {
	// MARK: - General
	
	static let Cancel = "Cancel"
	static let Continue = "Continue"
	static let Done = "Done"
	static let More = "More"
	
	static let _interpunct = "·"
	static let _octothorpe = "#"
	static let _em_dash = "—"
	static let _tilde = "~"
	
	static let Unknown_Artist = "Unknown Artist"
	static let Unknown_Album = "Unknown Album"
	static let Now_Playing = "Now Playing"
	static let Paused = "Paused"
	static let Apple_Music = "Apple Music"
	
	static let _message_welcome = "SongPocket shows and plays your Apple Music library."
	static let _message_empty = "Add music to your Apple Music library."
	static func NUMBER_albums_selected(_ num: Int) -> String {
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
	static func NUMBER_songs_selected(_ num: Int) -> String {
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
	
	static let Start_Playing = "Start Playing"
	static let Play = "Play"
	static func Randomize(for ids_lang: [String]) -> String {
		let en_US = "Randomize"
		for id_lang in ids_lang {
			let lang = Locale.Language(identifier: id_lang)
			guard let code_lang = lang.languageCode, code_lang == .english else { continue }
			switch lang.region { // Don’t use `Locale.region`; that matches the Settings app → Language & Region → Region.
				case .unitedKingdom, .southAfrica, .australia, .singapore, .ireland, .newZealand: return "Randomise" // As of iOS 18.2 developer beta 2, Photos says “Customise” for these variants of English.
				case .india, .unitedStates, .canada: return en_US // As of iOS 18.2 developer beta 2, Photos says “Customize” for these variants of English.
				default: return en_US
			}
		}
		return en_US
	}
	static let Add_to_Queue = "Add to Queue"
	
	static let Pause = "Pause"
	static let Skip_back_15_seconds = "Skip back 15 seconds" // As of iOS 16.5 RC 1, picture-in-picture videos use “Skip back 10 seconds” and “Skip forward 10 seconds”.
	static let Skip_forward_15_seconds = "Skip forward 15 seconds"
	
	static let Previous = "Previous"
	static let Restart = "Restart"
	static let Next = "Next"
	static let Repeat_One = "Repeat One"
	
	// MARK: - Editing
	
	static let Select = "Select"
	static let Selected = "Selected"
	static let Select_Range_Above = "Select Range Above"
	static let Select_Range_Below = "Select Range Below"
	static let Deselect_Range_Above = "Deselect Range Above"
	static let Deselect_Range_Below = "Deselect Range Below"
	
	static let Sort = "Sort"
	static let Recently_Added = "Recently Added"
	static let Recently_Released = "Recently Released"
	static let Track_Number = "Track Number"
	static let Shuffle = "Shuffle"
	static let Reverse = "Reverse"
	
	static let Move_Up = "Move up"
	static let Move_Down = "Move down"
	static let To_Top = "To Top"
	static let To_Bottom = "To Bottom"
}
