//
//  SortCommand.swift
//  LavaRock
//
//  Created by h on 2022-04-22.
//

import UIKit

enum SortCommand: CaseIterable {
	// For `Collection`s only
	case folder_name
	
	// For `Album`s only
	case album_newestRelease
	
	// For `Song`s only
	case song_trackNumber
	
	// For all types
	case random
	case reverse
	
	func localizedName() -> String {
		switch self {
			case .folder_name:
				return LRString.name
			case .album_newestRelease:
				return LRString.newestRelease
			case .song_trackNumber:
				return LRString.trackNumber
			case .random:
				return LRString.random
			case .reverse:
				return LRString.reverse
		}
	}
	
	func uiImage() -> UIImage? {
		switch self {
			case .folder_name:
				return UIImage(systemName: "textformat.abc")
			case .album_newestRelease:
				return UIImage(systemName: "calendar")
			case .song_trackNumber:
				return UIImage(systemName: "textformat.123")
			case .random:
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
