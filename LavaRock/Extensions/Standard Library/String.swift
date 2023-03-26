//
//  String.swift
//  LavaRock
//
//  Created by h on 2021-04-27.
//

extension String {
	func truncatedIfLonger(than maxLength: Int) -> String {
		let trimmed = prefix(maxLength - 1)
		if self == trimmed {
			return self
		} else {
			return "\(trimmed)\(LRString.ellipsis)"
		}
	}
	
	// Don’t sort `String`s by `<`. That puts all capital letters before all lowercase letters, meaning “Z” comes before “a”.
	func precedesAlphabeticallyFinderStyle(_ other: Self) -> Bool {
		let comparisonResult = localizedStandardCompare(other) // The comparison method that the Finder uses
		switch comparisonResult {
			case .orderedAscending:
				return true
			case .orderedSame:
				return true
			case .orderedDescending:
				return false
		}
	}
}
