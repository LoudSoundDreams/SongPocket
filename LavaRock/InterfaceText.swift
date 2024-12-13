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
	static let _tilde = "~"
	
	static let Now_Playing = "Now Playing"
	static let Paused = "Paused"
	static let Apple_Music = "Apple Music"
	
	static let _welcome_title = "Hi!"
	static let _welcome_subtitle = "SongPocket shows and plays your Apple Music library."
	static let no_music = "No music"
	static let _empty_library_message = "Add music to your Apple Music library."
	static let No_artwork = "No artwork"
	
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
	static func Track_VALUE(_ value: String) -> String { "Track \(value)" }
	
	// MARK: - Playback
	
	static let Go_to_Album = "Go to Album"
	
	static let Start_Playing = "Start Playing"
	static let Play = "Play"
	static func Randomize(for ids_lang: [String]) -> String {
		return "Jumble"
		/*
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
		 */
	}
	static let Play_Later = "Play Later"
	
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
	static let Select_Up = "Select Up"
	static let Select_Down = "Select Down"
	static let Deselect_Up = "Deselect Up"
	static let Deselect_Down = "Deselect Down"
	
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
