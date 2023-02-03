//
//  LibrarySortOption.swift
//  LavaRock
//
//  Created by h on 2022-04-22.
//

import UIKit

enum LibrarySortOption: CaseIterable {
	// For `Collection`s only
	case title
	
	// For `Album`s only
	case newestFirst
	case oldestFirst
	
	// For `Song`s only
	case trackNumber
	
	// For all types
	case scramble
	case reverse
	
	func localizedName() -> String {
		switch self {
		case .title:
			return LRString.title
		case .newestFirst:
			return LRString.newest
		case .oldestFirst:
			return LRString.oldest
		case .trackNumber:
			return LRString.trackNumber
		case .scramble:
			return LRString.scramble
		case .reverse:
			return LRString.reverse
		}
	}
	
	func uiImage() -> UIImage? {
		switch self {
		case .title:
			return UIImage(systemName: "textformat.abc")
		case .newestFirst:
			return UIImage(systemName: "hourglass.bottomhalf.filled")
		case .oldestFirst:
			return UIImage(systemName: "hourglass.tophalf.filled")
		case .trackNumber:
			return UIImage(systemName: "textformat.123")
		case .scramble:
			return UIImage(systemName: "shuffle")
		case .reverse:
			return UIImage(systemName: "arrow.turn.right.up")
		}
	}
	
	init?(localizedName: String) {
		guard let matchingCase = Self.allCases.first(where: {
			localizedName == $0.localizedName()
		}) else {
			return nil
		}
		self = matchingCase
	}
}
