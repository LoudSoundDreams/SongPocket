// For consistency throughout the app.

extension Double {
	static var one_eighth: Self { 1/8 }
	static var one_fourth: Self { 1/4 }
	static var one_half: Self { 1/2 }
}
extension CGFloat {
	static var one_half: Self { 1/2 }
	static var eight: Self { 8 }
}

import SwiftUI
extension Color {
	static var white_one_eighth: Color { Color(white: .one_eighth) }
	static var white_one_fourth: Color { Color(white: .one_fourth) }
	static var white_one_half: Color { Color(white: .one_half) }
}
extension View {
	// As of iOS 18.2 developer beta 4, Apple Music uses this for “Recently Added”.
	func font_title2_semibold() -> some View { font(.title2).fontWeight(.semibold) }
	
	// As of iOS 18.2 developer beta 4, Apple Music uses this for album titles.
	func font_title3_bold() -> some View { font(.title3).bold() }
	
	// As of iOS 16.6, Apple Music uses this for the current song title on the “now playing” screen.
	func font_headline() -> some View { font(.headline) }
	
	/*
	 As of iOS 16.6, Apple Music uses this for…
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

/*
 extension UserDefaults {
 enum Key: String, CaseIterable {
 }
 }
 */
/*
 Deprecated after version 2.7.1
 Introduced in version ?
 "hasEverImportedFromMusic"
 Values: Bool
 
 Deprecated after version 1.13.3
 Introduced in version 1.8
 "nowPlayingIcon"
 Values: String
 Introduced in version 1.12
 • "Paw"
 • "Luxo"
 Introduced in version 1.8
 • "Speaker"
 • "Fish"
 Deprecated after version 1.11.2:
 • "Bird"
 • "Sailboat"
 • "Beach umbrella"
 
 Deprecated after version 1.13.3
 Introduced in version 1.0
 "accentColorName"
 Values: String
 • "Blueberry"
 • "Grape"
 • "Strawberry"
 • "Tangerine"
 • "Lime"
 
 Deprecated after version 1.13
 Introduced in version 1.6
 "appearance"
 Values: Int
 • `0` for “match system”
 • `1` for “always light”
 • `2` for “always dark”
 
 Deprecated after version 1.7
 Introduced in version ?
 "shouldExplainQueueAction"
 Values: Bool
 */
