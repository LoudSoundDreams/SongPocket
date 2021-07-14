//
//  extension String.swift
//  LavaRock
//
//  Created by h on 2021-04-27.
//

extension String {
	
	// Don't sort Strings by <. That puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
	func precedesAlphabeticallyFinderStyle(_ other: Self) -> Bool {
		let comparisonResult = localizedStandardCompare(other) // The comparison method that the Finder uses
		return comparisonResult == .orderedAscending
	}
	
}
