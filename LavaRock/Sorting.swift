// 2022-04-22

import UIKit

enum AlbumOrder {
	case random
	case reverse
	
	case recently_added
	case recently_released
	
	@MainActor func action(handler: @escaping () -> Void) -> UIAction {
		return UIAction(
			title: { switch self {
				case .random: return InterfaceText.Shuffle
				case .reverse: return InterfaceText.Reverse
				case .recently_added: return InterfaceText.Recently_Added
				case .recently_released: return InterfaceText.Recently_Released
			}}(),
			image: { switch self {
				case .random: return UIImage(systemName: "shuffle")
				case .reverse: return UIImage(systemName: "arrow.turn.right.up")
				case .recently_added: return UIImage(systemName: "plus.square")
				case .recently_released: return UIImage(systemName: "calendar")
			}}(),
			handler: { _ in handler() })
	}
	
	@MainActor func reindex(_ in_original_order: [ZZZAlbum]) {
		let replace_at: [Int64] = in_original_order.map { $0.index }
		let arranged: [ZZZAlbum] = { switch self {
			case .random: return in_original_order.in_any_other_order()
			case .reverse: return in_original_order.reversed()
				
				// Sort stably: keep elements in the same order if they have the same release date, artist, or so on.
				
			case .recently_added:
				// 10,000 albums takes 11.4s in 2024.
				let now = Date.now // Keeps `Album`s without date added at the beginning, maintaining their current order.
				let albums_and_first_added: [(album: ZZZAlbum, first_added: Date)] = in_original_order.map { album in (
					album: album,
					first_added: {
						let mkSongs = Librarian.shared.mkSection(mpidAlbum: album.albumPersistentID)?.items ?? [] // As of iOS 17.6 developer beta 2, `MusicKit.Album.libraryAddedDate` reports the latest date you added one of its songs, not the earliest. That matches how the Apple Music app sorts its Library tab’s Recently Added section, but doesn’t match how it sorts playlists by “Recently Added”, which is actually by date created.
						// I prefer using date created, because it’s stable: that’s the order we naturally get by adding new albums at the top when we first import them, regardless of when that is.
						return ZZZAlbum.date_created(mkSongs) ?? now
					}()
				)}
				let sorted = albums_and_first_added.sorted_stably { // 10,000 albums takes 41ms in 2024.
					$0.first_added == $1.first_added // MusicKit’s granularity is 1 second; we can’t meaningfully compare items added within the same second.
				} are_in_order: {
					$0.first_added > $1.first_added
				}
				return sorted.map { $0.album }
			case .recently_released:
				let albums_and_dates_released: [(album: ZZZAlbum, date_released: Date?)] = in_original_order.map {(
					album: $0,
					date_released: Librarian.shared.infoAlbum(mpidAlbum: $0.albumPersistentID)?._date_released
				)}
				let sorted = albums_and_dates_released.sorted_stably {
					$0.date_released == $1.date_released
				} are_in_order: {
					// Move unknown release date to the end
					guard let date_right = $1.date_released else { return true }
					guard let date_left = $0.date_released else { return false }
					return date_left > date_right
				}
				return sorted.map { $0.album }
		}}()
		arranged.indices.forEach { counter in
			arranged[counter].index = replace_at[counter]
		}
	}
}

enum SongOrder {
	case random
	case reverse
	
	case track
	
	@MainActor func action(handler: @escaping () -> Void) -> UIAction {
		return UIAction(
			title: { switch self {
				case .random: return InterfaceText.Shuffle
				case .reverse: return InterfaceText.Reverse
				case .track: return InterfaceText.Track_Number
			}}(),
			image: { switch self {
				case .random: return UIImage(systemName: "shuffle")
				case .reverse: return UIImage(systemName: "arrow.turn.right.up")
				case .track: return UIImage(systemName: "number")
			}}(),
			handler: { _ in handler() })
	}
	
	@MainActor func reindex(_ in_original_order: [ZZZSong]) {
		let replace_at: [Int64] = in_original_order.map { $0.index }
		let arranged: [ZZZSong] = { switch self {
			case .random: return in_original_order.in_any_other_order()
			case .reverse: return in_original_order.reversed()
				
			case .track: return Self.sorted_numerically(strict: false, in_original_order)
		}}()
		arranged.indices.forEach { counter in
			arranged[counter].index = replace_at[counter]
		}
	}
	
	@MainActor static func sorted_numerically(strict: Bool, _ input: [ZZZSong]) -> [ZZZSong] {
		let songs_and_infos: [(song: ZZZSong, info: (some InfoSong)?)] = input.map {(
			song: $0,
			info: ZZZSong.InfoSong(MPID: $0.persistentID)
		)}
		let sorted = songs_and_infos.sorted_stably {
			let left = $0.info; let right = $1.info
			return (
				left?.disc_number_on_disk == right?.disc_number_on_disk &&
				left?.track_number_on_disk == right?.track_number_on_disk
			)
		} are_in_order: {
			guard let right = $1.info else { return true }
			guard let left = $0.info else { return false }
			return Self.__precedes_numerically(strict: false, left, right)
		}
		return sorted.map { $0.song }
	}
	static func precedes_numerically(
		strict: Bool,
		_ left: MKSong, _ right: MKSong
	) -> Bool {
		let disc_left = left.discNumber
		let disc_right = right.discNumber
		guard disc_left == disc_right else {
			guard let disc_right else { return true }
			guard let disc_left else { return false }
			return disc_left < disc_right
		}
		
		let track_right = right.trackNumber
		let track_left = left.trackNumber
		guard track_left == track_right else {
			guard let track_right else { return true }
			guard let track_left else { return false }
			return track_left < track_right
		}
		
		guard strict else { return true }
		
		let title_left = left.title
		let title_right = right.title
		guard title_left == title_right else {
			return title_left.precedes_in_Finder(title_right)
		}
		
		return left.id.rawValue < right.id.rawValue
	}
	static func __precedes_numerically(
		strict: Bool,
		_ left: some InfoSong, _ right: some InfoSong
	) -> Bool {
		let disc_left = left.disc_number_on_disk
		let disc_right = right.disc_number_on_disk
		guard disc_left == disc_right else {
			return disc_left < disc_right
		}
		
		let track_left = left.track_number_on_disk
		let track_right = right.track_number_on_disk
		guard track_left == track_right else {
			guard track_right != 0 else { return true }
			guard track_left != 0 else { return false }
			return track_left < track_right
		}
		
		guard strict else { return true }
		
		let title_left = left.title_on_disk
		let title_right = right.title_on_disk
		guard title_left == title_right else {
			guard let title_right else { return true }
			guard let title_left else { return false }
			return title_left.precedes_in_Finder(title_right)
		}
		
		return left.id_song < right.id_song
	}
}

// MARK: - Title

extension String {
	// Don’t sort `String`s by `<`. That puts all capital letters before all lowercase letters, meaning “Z” comes before “a”.
	func precedes_in_Finder(_ other: Self) -> Bool {
		let comparison = localizedStandardCompare(other) // The comparison method that the Finder uses
		switch comparison {
			case .orderedAscending: return true
			case .orderedSame: return true
			case .orderedDescending: return false
		}
	}
}
