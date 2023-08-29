//
//  DefaultsKey.swift
//  LavaRock
//
//  Created by h on 2022-02-27.
//

// Keeping these keys in one place helps us keep them unique.
enum DefaultsKey: String, CaseIterable {
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
