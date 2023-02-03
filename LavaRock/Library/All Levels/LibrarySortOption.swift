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
			switch Int.random(in: 1...6) {
			case 1:
				return UIImage(systemName: "die.face.1")
			case 2:
				return UIImage(systemName: "die.face.2")
			case 4:
				return UIImage(systemName: "die.face.4")
			case 5:
				return UIImage(systemName: "die.face.5")
			case 6:
				return UIImage(systemName: "die.face.6")
			default:
				return UIImage(systemName: "die.face.3") // Most recognizable. If we weren’t doing this little joke, we’d use this icon every time. (Second–most recognizable is 6.)
			}
		case .reverse:
			return UIImage(systemName: "arrow.up.and.down")
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
