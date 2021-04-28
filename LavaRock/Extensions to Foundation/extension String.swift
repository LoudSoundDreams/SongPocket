//
//  extension String.swift
//  LavaRock
//
//  Created by h on 2021-04-27.
//

extension String {
	
	func precedesInAlphabeticalOrderFinderStyle(_ otherString: Self) -> Bool {
		let comparisonResult = localizedStandardCompare(otherString) // The comparison method that the Finder uses
		return comparisonResult == .orderedAscending
	}
	
}
