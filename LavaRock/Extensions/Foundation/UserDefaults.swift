//
//  UserDefaults.swift
//  LavaRock
//
//  Created by h on 2020-12-30.
//

import Foundation

enum LRUserDefaultsKey: String, CaseIterable {
	case lighting = "appearance"
	case accentColor = "accentColorName"
	
	case hasEverImportedFromMusic = "hasEverImportedFromMusic"
	case shouldExplainQueueAction = "shouldExplainQueueAction"
}

extension UserDefaults {
	final func deleteAllValuesExcept(forKeys keysToKeep: Set<String>) {
		dictionaryRepresentation().forEach { (key, _) in
			if !keysToKeep.contains(key) {
				removeObject(forKey: key)
			}
		}
	}
}
