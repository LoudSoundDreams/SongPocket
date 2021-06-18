//
//  UserDefaults.swift
//  LavaRock
//
//  Created by h on 2020-12-30.
//

import Foundation

enum LRUserDefaultsKey: String, CaseIterable {
	// Remember: These case names are also their raw values as strings.
	case accentColorName
	case shouldExplainQueueAction
	
	static let rawValues = allCases.map { $0.rawValue }
}

extension UserDefaults {
	
	final func deleteAllEntries(exceptWithKeys keysToKeep: [String]) {
		let oldEntries = dictionaryRepresentation() // Remember: This method operates on the instance of UserDefaults we're calling it on.
		
		var newEntries = oldEntries
		newEntries.removeAll() // To match the type of existingEntries
		for key in keysToKeep {
			let value = oldEntries[key]
			newEntries[key] = value
		}
		
		setPersistentDomain(newEntries, forName: Bundle.main.bundleIdentifier!)
	}
	
}
