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
			return "\(trimmed)\(LocalizedString.ellipsis)"
		}
	}
	
	func trimmingWhitespaceAtEnd() -> String {
		var runningResult = self
		while
			let lastCharacter = runningResult.last,
			lastCharacter.isWhitespace
		{
			runningResult.removeLast()
		}
		return runningResult
	}
	
	func endsOrHasWhitespaceAfter(dropFirstCount: Int) -> Bool {
		let rest = dropFirst(dropFirstCount)
		guard let next = rest.first else {
			return true
		}
		return next.isWhitespace
	}
	
	// Don't sort Strings by <. That puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
	func precedesAlphabeticallyFinderStyle(_ other: Self) -> Bool {
		let comparisonResult = localizedStandardCompare(other) // The comparison method that the Finder uses
		return comparisonResult == .orderedAscending
	}
	
}
