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
