//
//  SortCommand.swift
//  LavaRock
//
//  Created by h on 2022-04-22.
//

import UIKit

enum SortCommand: CaseIterable {
	case random
	case reverse
	
	case folder_name
	
	case album_released
	
	case song_track
	case song_added
	
	func localizedName() -> String {
		switch self {
			case .random: return LRString.random
			case .reverse: return LRString.reverse
			case .folder_name: return LRString.name
			case .album_released: return LRString.recentlyReleased
			case .song_track: return LRString.trackNumber
			case .song_added: return LRString.recentlyAdded
		}
	}
	
	func uiImage() -> UIImage? {
		switch self {
			case .random:
				switch Int.random(in: 1...6) {
					case 1: return UIImage(systemName: "die.face.1")
					case 2: return UIImage(systemName: "die.face.2")
					case 4: return UIImage(systemName: "die.face.4")
					case 5: return UIImage(systemName: "die.face.5")
					case 6: return UIImage(systemName: "die.face.6")
					default: return UIImage(systemName: "die.face.3") // Most recognizable. If we weren’t doing this little joke, we’d use this icon every time. (Second–most recognizable is 6.)
				}
			case .reverse: return UIImage(systemName: "arrow.up.and.down")
			case .folder_name: return UIImage(systemName: "character")
			case .album_released: return UIImage(systemName: "sparkles")
			case .song_track: return UIImage(systemName: "opticaldisc")
			case .song_added: return UIImage(systemName: "clock")
		}
	}
}
