//
//  extension String.swift
//  LavaRock
//
//  Created by h on 2021-04-27.
//

extension String {
	
	func precedesAlphabeticallyFinderStyle(_ other: Self) -> Bool {
		let comparisonResult = localizedStandardCompare(other) // The comparison method that the Finder uses
		return comparisonResult == .orderedAscending
	}
	
}
