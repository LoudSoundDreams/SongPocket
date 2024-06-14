import SwiftUI

// Reference hard-coded numbers here to keep them consistent throughout the app.
extension CGFloat {
	static var oneHalf: Self { 1/2 }
	static var eight: Self { 8 }
}
extension Color {
	static let grey_oneEighth = Self(
		hue: 0,
		saturation: 0,
		brightness: pow(.oneHalf, 3)
	)
}

// Keep keys here to ensure they’re unique.
extension UserDefaults {
	enum Key: String, CaseIterable {
		// Introduced in version ?
		case hasSavedDatabase = "hasEverImportedFromMusic"
		
		/*
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
	}
}
