// For consistency throughout the app.

import SwiftUI

extension Double {
	static var one_eighth: Self { 1/8 }
	static var one_fourth: Self { 1/4 }
	static var one_half: Self { 1/2 }
}
extension CGFloat {
	static var one_half: Self { 1/2 }
	static var eight: Self { 8 }
}

extension View {
	// As of iOS 18.2 developer beta 4, Apple Music uses this for album titles.
	func font_title3_bold() -> some View { font(.title3).bold() }
	
	/*
	 As of iOS 16.6, Apple Music uses this for …
	 • Genre, release year, and “Lossless” on album details views
	 • Radio show titles
	 */
	func font_caption2_bold() -> some View { font(.caption2).bold() }
	
	// As of iOS 16.6, Apple Music uses this for artist names on song rows.
	func font_footnote() -> some View { font(.footnote) }
	
	func font_body_dynamicType_up_to_xxxLarge() -> some View {
		font(.body).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
	}
}

enum InterfaceText {
	static let Cancel = "Cancel"
	static let Start = "Start"
	static let Done = "Done"
	static let More = "More"
	
	static let _interpunct = "·"
	static let _octothorpe = "#"
	static let _tilde = "~"
	
	static let Now_Playing = "Now Playing"
	static let Paused = "Paused"
	static let Open_Apple_Music = "Open Apple Music"
	
	static let _welcome_title = "Hi!"
	static let _welcome_subtitle = "SongPocket shows and plays your Apple Music library."
	static let No_music = "No music"
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
	
	// MARK: Playback
	
	static let Start_Playing = "Start Playing"
	static let Play = "Play"
	static let Add_to_Queue = "Add to Queue"
	static func Randomize(for_localeLanguageIdentifiers langIDs: [String]) -> String {
		return "Jumble"
		/*
		 let en_US = "Randomize"
		 for langID in langIDs { // Return early with the first match.
		 let lang = Locale.Language(identifier: langID)
		 guard lang.languageCode == Locale.LanguageCode.english
		 else { continue }
		 switch lang.region { // Don’t use `Locale.region`; that matches the Settings app → Language & Region → Region.
		 case .unitedKingdom, .southAfrica, .australia, .singapore, .ireland, .newZealand: return "Randomise" // As of iOS 18.2 developer beta 2, Photos says “Customise” for these variants of English.
		 case .india, .unitedStates, .canada: return en_US // As of iOS 18.2 developer beta 2, Photos says “Customize” for these variants of English.
		 default: return en_US
		 }
		 }
		 return en_US
		 */
	}
	
	static let Pause = "Pause"
	static let Restart = "Restart"
	static let Skip_back_15_seconds = "Skip back 15 seconds" // As of iOS 16.5 RC 1, picture-in-picture videos use “Skip back 10 seconds” and “Skip forward 10 seconds”.
	static let Skip_forward_15_seconds = "Skip forward 15 seconds"
	static let Previous = "Previous"
	static let Next = "Next"
	
	static let Repeat_One = "Repeat One"
	static let Go_to_Album = "Go to Album"
	
	// MARK: Editing
	
	static let Select = "Select"
	static let Select_Up = "Select Up"
	static let Select_Down = "Select Down"
	static let Selected = "Selected"
	static let Deselect_Up = "Deselect Up"
	static let Deselect_Down = "Deselect Down"
	
	static let Sort = "Sort"
	static let Reverse = "Reverse"
	static let Shuffle = "Shuffle"
	static let Recently_Added = "Recently Added"
	static let Recently_Released = "Recently Released"
	static let Track_Number = "Track Number"
	
	static let Move_Up = "Move up"
	static let Move_Down = "Move down"
	static let To_Top = "To Top"
	static let To_Bottom = "To Bottom"
}

// MARK: - UserDefaults

/*
 "hasEverImportedFromMusic"
 Values: Bool
 Used in versions ? through 2.7.1
 
 "nowPlayingIcon"
 Values: String
 Used in versions 1.8 through 1.13.3:
 • "Speaker"
 • "Fish"
 Used in versions 1.12 through 1.13.3:
 • "Paw"
 • "Luxo"
 Used in versions 1.8 through 1.11.2:
 • "Bird"
 • "Sailboat"
 • "Beach umbrella"
 
 "accentColorName"
 Values: String
 Used in versions 1.0 through 1.13.3
 • "Blueberry"
 • "Grape"
 • "Strawberry"
 • "Tangerine"
 • "Lime"
 
 "appearance"
 Values: Int
 Used in versions 1.6 through 1.13
 • `0` for “match system”
 • `1` for “always light”
 • `2` for “always dark”
 
 "shouldExplainQueueAction"
 Values: Bool
 Used in versions ? through 1.7
 */
