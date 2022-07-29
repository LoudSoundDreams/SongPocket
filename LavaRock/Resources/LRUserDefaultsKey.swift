//
//  LRUserDefaultsKey.swift
//  LavaRock
//
//  Created by h on 2022-02-27.
//

enum LRUserDefaultsKey: String, CaseIterable {
	case lighting = "appearance"
	case accentColor = "accentColorName"
	
	case hasEverImportedFromMusic = "hasEverImportedFromMusic"
	
	// Last used in version 1.7
	case shouldExplainQueueAction = "shouldExplainQueueAction"
}
