//
//  DefaultsKey.swift
//  LavaRock
//
//  Created by h on 2022-02-27.
//

// Keeping these keys in one place helps us keep them unique.
enum DefaultsKey: String, CaseIterable {
	// Introduced in version 1.8
	case avatar = "nowPlayingIcon"
	
	// Introduced in version ??
	case hasSavedDatabase = "hasEverImportedFromMusic"
	
	// Introduced in version 1.0
	case accentColor = "accentColorName"
	
	/*
	 "appearance"
	 Introduced in version 1.6
	 Deprecated after version 1.13
	 Values: Int
	 • `0` for “match system”
	 • `1` for “always light”
	 • `2` for “always dark”
	 
	 "shouldExplainQueueAction"
	 Introduced in version ??
	 Deprecated after version 1.7
	 Values: Bool
	 */
}
