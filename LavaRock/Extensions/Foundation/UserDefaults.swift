//
//  UserDefaults.swift
//  LavaRock
//
//  Created by h on 2020-12-30.
//

import Foundation

enum LRUserDefaultsKey: String, CaseIterable {
	case appearance = "appearance"
	case accentColor = "accentColorName"
	
	case hasEverImportedFromMusic
	
	case shouldExplainQueueAction
}

extension UserDefaults {
	final func deleteAllEntriesExcept(withKeys keysToKeep: [String]) {
		let oldEntries = dictionaryRepresentation()
		
		var newEntries = oldEntries
		newEntries.removeAll() // To match the type of oldEntries
		keysToKeep.forEach { key in
			let value = oldEntries[key]
			newEntries[key] = value
		}
		
		setPersistentDomain(newEntries, forName: Bundle.main.bundleIdentifier!)
	}
}
