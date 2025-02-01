// For consistency or uniqueness throughout the app.

import SwiftUI

extension Double {
	static var one_half: Self { 1/2 }
	static var one_fourth: Self { 1/4 }
	static var one_eighth: Self { 1/8 }
}
extension CGFloat {
	static var eight: Self { 8 }
}

extension Animation {
	static func linear_quick() -> Self {
		linear(duration: .one_eighth)
	}
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
	
	func dynamicType_default_to_plus_3() -> some View {
		dynamicTypeSize(.large ... .xxxLarge)
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
	static let Apple_Music = "Apple Music"
	
	static let _welcome_title = "Hi!"
	static let _welcome_subtitle = "SongPocket shows and plays your Apple Music library."
	static let No_music = "No music"
	static let _empty_library_message = "Add music to your Apple Music library."
	static let No_artwork = "No artwork"
	static let Show_artwork = "Show artwork"
	
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
	static let Add_to_Queue = "Play Later"
	static let Jumble = "Jumble"
	
	static let Pause = "Pause"
	static let Restart = "Restart"
	static let Skip_back_15_seconds = "Skip back 15 seconds" // As of iOS 16.5 RC 1, picture-in-picture videos use “Skip back 10 seconds” and “Skip forward 10 seconds”.
	static let Skip_forward_15_seconds = "Skip forward 15 seconds"
	static let Previous = "Previous"
	static let Next = "Next"
	
	static let Repeat_One = "Repeat One"
	static let Go_to_Artwork = "Go to Artwork"
	
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
	
	private static func Randomize(
		for_locale_preferredLanguages langIDs: [String]
	) -> String {
		let en_US = "Randomize"
		for langID in langIDs { // Return early with the first match.
			let lang = Locale.Language(identifier: langID)
			guard lang.languageCode == Locale.LanguageCode.english
			else { continue }
			switch lang.region { // Don’t use `Locale.region`; that matches the Settings app → Language & Region → Region.
					// As of iOS 18.2 developer beta 2, for these English variants, the Photos app says …
				case .unitedKingdom, .southAfrica, .australia, .singapore, .ireland, .newZealand: return "Randomise" // “Customise”
				case .india, .unitedStates, .canada: return en_US // “Customize”
				default: return en_US
			}
		}
		return en_US
	}
}

// MARK: - Internal

/*
 UserDefaults keys
 
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

extension Notification.Name {
	static let librarian_merged = Self("LR_Merged")
	static let exhibit_artifacts = Self("LR_Artifacts")
	static let exhibit_focus = Self("LR_Focus")
	static let song_activation = Self("LR_Song_Activation")
}

enum SF {
	static let select_fill = "checkmark.circle.fill"
	static let select_up = "arrowtriangle.up.circle"
	static let select_down = "arrowtriangle.down.circle"
	static let deselect_up = "arrowtriangle.up.circle.fill"
	static let deselect_down = "arrowtriangle.down.circle.fill"
	
	static let reverse = "arrow.uturn.up"
	static let shuffle = "shuffle"
	static let to_top = "arrow.up.to.line"
	static let to_bottom = "arrow.down.to.line"
	
	static let play_hollow = "play"
	static func die_random() -> String {
		switch Int.random(in: 1...6) {
			case 1: return "die.face.1"
			case 2: return "die.face.2"
			case 3: return "die.face.3"
			case 4: return "die.face.4"
			case 5: return "die.face.5"
			default: return "die.face.6"
		}
	}
	static let add_to_queue = "text.line.last.and.arrowtriangle.forward"
	
	static let play_circle = "play.circle.fill"
	static let pause_circle = "pause.circle.fill"
	static let play_bold = "play.fill"
	static let pause_bold = "pause.fill"
	static let rewind = "arrow.counterclockwise"
	static let jump_back_15 = "gobackward.15"
	static let jump_forward_15 = "goforward.15"
	static let previous_bold = "backward.end.fill"
	static let next_bold = "forward.end.fill"
	static let repeat_1 = "repeat.1"
	static let photo = "photo"
	
	static let ellipsis = "ellipsis.circle.fill"
	static let app_external = "arrow.up.forward.app"
}
