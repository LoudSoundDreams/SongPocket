//
//  LRUserDefaultsKey.swift
//  LavaRock
//
//  Created by h on 2022-02-27.
//

enum LRUserDefaultsKey: String, CaseIterable {
	// First used in version 1.6
	case lighting = "appearance"
	
	// First used in version ?
	case hasEverImportedFromMusic = "hasEverImportedFromMusic"
	
	// First used in version 1.0
	case accentColor = "accentColorName"
	
	// Last used in version 1.7
	case shouldExplainQueueAction = "shouldExplainQueueAction"
}
