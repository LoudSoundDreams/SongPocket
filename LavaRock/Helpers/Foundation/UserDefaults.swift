//
//  UserDefaults.swift
//  LavaRock
//
//  Created by h on 2020-12-30.
//

import Foundation

extension UserDefaults {
	final func deleteAllValuesExceptForLRUserDefaultsKeys() {
		let keysToKeep = Set(LRUserDefaultsKey.allCases.map { $0.rawValue })
		dictionaryRepresentation().forEach { (key, _) in
			if !keysToKeep.contains(key) {
				removeObject(forKey: key)
			}
		}
	}
}
