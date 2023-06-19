//
//  LRUserDefaultsKey.swift
//  LavaRock
//
//  Created by h on 2022-02-27.
//

// Keeping these keys in one place helps us keep them unique.
enum LRUserDefaultsKey: String, CaseIterable {
	// Introduced in version 1.8
	case avatar = "nowPlayingIcon"
	
	// Introduced in version 1.6
	case lighting = "appearance"
	
	// Introduced in version ?
	case hasSavedDatabase = "hasEverImportedFromMusic"
	
	// Introduced in version 1.0
	case accentColor = "accentColorName"
	
	/*
	 Deprecated after version 1.7
	 "shouldExplainQueueAction"
	 */
}
