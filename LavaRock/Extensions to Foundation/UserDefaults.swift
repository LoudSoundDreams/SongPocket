//
//  UserDefaults.swift
//  LavaRock
//
//  Created by h on 2020-12-30.
//

import Foundation

enum LRUserDefaultsKey: String, CaseIterable {
	case accentColorName = "accentColorName"
	case shouldExplainQueueAction = "shouldExplainQueueAction"
	
	static func rawValues() -> [String] {
		let result = Self.allCases.map { $0.rawValue }
		return result
	}
}

extension UserDefaults {
	
	final func deleteAllEntries(exceptWithKeys keysToKeep: [String]) {
		let existingEntries = dictionaryRepresentation() // Remember: This method operates on the instance of UserDefaults we're calling it on.
		
		var entriesToKeep = existingEntries
		entriesToKeep.removeAll() // To match the type of existingEntries
		for keyToKeep in keysToKeep {
			let valueToKeep = existingEntries[keyToKeep]
			entriesToKeep[keyToKeep] = valueToKeep
		}
		
		setPersistentDomain(entriesToKeep, forName: Bundle.main.bundleIdentifier!)
	}
	
}
