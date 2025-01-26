// 2022-04-22

import UIKit

enum AlbumOrder {
	case reverse
	case random
	
	case recently_added
	case recently_released
	
	var name: String {
		switch self {
			case .reverse: return InterfaceText.Reverse
			case .random: return InterfaceText.Shuffle
			case .recently_added: return InterfaceText.Recently_Added
			case .recently_released: return InterfaceText.Recently_Released
		}
	}
	var sf_symbol: String {
		switch self {
			case .reverse: return SF.reverse
			case .random: return SF.shuffle
			case .recently_added: return "plus.circle"
			case .recently_released: return "calendar"
		}
	}
}

enum SongOrder {
	case reverse
	case random
	
	case track
	
	var name: String {
		switch self {
			case .reverse: return InterfaceText.Reverse
			case .random: return InterfaceText.Shuffle
			case .track: return InterfaceText.Track_Number
		}
	}
	var sf_symbol: String {
		switch self {
			case .reverse: return SF.reverse
			case .random: return SF.shuffle
			case .track: return "number"
		}
	}
	
	static func is_increasing_by_track(
		same_every_time: Bool,
		_ left: MKSong, _ right: MKSong
	) -> Bool {
		let disc_left: Int? = left.discNumber
		let disc_right: Int? = right.discNumber
		if disc_left != disc_right {
			guard let disc_right else { return true }
			guard let disc_left else { return false }
			return disc_left < disc_right
		}
		
		let track_right: Int? = right.trackNumber
		let track_left: Int? = left.trackNumber
		if track_left != track_right {
			guard let track_right else { return true }
			guard let track_left else { return false }
			return track_left < track_right
		}
		
		guard same_every_time else { return false }
		
		let title_left: String = left.title
		let title_right: String = right.title
		if title_left != title_right {
			return title_left.is_increasing_in_Finder(title_right)
		}
		
		return left.id.rawValue < right.id.rawValue
	}
}
