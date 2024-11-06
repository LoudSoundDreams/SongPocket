// 2022-04-22

import UIKit

enum AlbumOrder {
	case random
	case reverse
	
	case recentlyAdded
	case recentlyReleased
	
	@MainActor func action(handler: @escaping () -> Void) -> UIAction {
		return UIAction(
			title: { switch self {
				case .random: return InterfaceText.Shuffle
				case .reverse: return InterfaceText.Reverse
				case .recentlyAdded: return InterfaceText.Recently_Added
				case .recentlyReleased: return InterfaceText.Recently_Released
			}}(),
			image: { switch self {
				case .random: return UIImage(systemName: "shuffle")
				case .reverse: return UIImage(systemName: "arrow.turn.right.up")
				case .recentlyAdded: return UIImage(systemName: "plus.square")
				case .recentlyReleased: return UIImage(systemName: "calendar")
			}}(),
			handler: { _ in handler() })
	}
	
	@MainActor func reindex(_ inOriginalOrder: [ZZZAlbum]) {
		let replaceAt: [Int64] = inOriginalOrder.map { $0.index }
		let arranged: [ZZZAlbum] = { switch self {
			case .random: return inOriginalOrder.inAnyOtherOrder()
			case .reverse: return inOriginalOrder.reversed()
				
				// Sort stably: keep elements in the same order if they have the same release date, artist, or so on.
				
			case .recentlyAdded:
				// 10,000 albums takes 11.4s in 2024.
				let now = Date.now // Keeps `Album`s without date added at the beginning, maintaining their current order.
				let albumsAndFirstAdded: [(album: ZZZAlbum, firstAdded: Date)] = inOriginalOrder.map { album in (
					album: album,
					firstAdded: {
						let mkSongs = Librarian.shared.mkSection(mpidAlbum: album.albumPersistentID)?.items ?? [] // As of iOS 17.6 developer beta 2, `MusicKit.Album.libraryAddedDate` reports the latest date you added one of its songs, not the earliest. That matches how the Apple Music app sorts its Library tab’s Recently Added section, but doesn’t match how it sorts playlists by “Recently Added”, which is actually by date created.
						// I prefer using date created, because it’s stable: that’s the order we naturally get by adding new albums at the top when we first import them, regardless of when that is.
						return ZZZAlbum.date_created(mkSongs) ?? now
					}()
				)}
				let sorted = albumsAndFirstAdded.sortedStably { // 10,000 albums takes 41ms in 2024.
					$0.firstAdded == $1.firstAdded // MusicKit’s granularity is 1 second; we can’t meaningfully compare items added within the same second.
				} areInOrder: {
					$0.firstAdded > $1.firstAdded
				}
				return sorted.map { $0.album }
			case .recentlyReleased:
				let albums_and_dates_released: [(album: ZZZAlbum, date_released: Date?)] = inOriginalOrder.map {(
					album: $0,
					date_released: Librarian.shared.infoAlbum(mpidAlbum: $0.albumPersistentID)?._release_date
				)}
				let sorted = albums_and_dates_released.sortedStably {
					$0.date_released == $1.date_released
				} areInOrder: {
					// Move unknown release date to the end
					guard let date_right = $1.date_released else { return true }
					guard let date_left = $0.date_released else { return false }
					return date_left > date_right
				}
				return sorted.map { $0.album }
		}}()
		arranged.indices.forEach { counter in
			arranged[counter].index = replaceAt[counter]
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
	
	@MainActor func reindex(_ inOriginalOrder: [ZZZSong]) {
		let replaceAt: [Int64] = inOriginalOrder.map { $0.index }
		let arranged: [ZZZSong] = { switch self {
			case .random: return inOriginalOrder.inAnyOtherOrder()
			case .reverse: return inOriginalOrder.reversed()
				
			case .track: return Self.sortedNumerically(strict: false, inOriginalOrder)
		}}()
		arranged.indices.forEach { counter in
			arranged[counter].index = replaceAt[counter]
		}
	}
	
	@MainActor static func sortedNumerically(strict: Bool, _ input: [ZZZSong]) -> [ZZZSong] {
		let songsAndInfos: [(song: ZZZSong, info: (some InfoSong)?)] = input.map {(
			song: $0,
			info: ZZZSong.InfoSong(MPID: $0.persistentID)
		)}
		let sorted = songsAndInfos.sortedStably {
			let left = $0.info; let right = $1.info
			return (
				left?.disc_number_on_disk == right?.disc_number_on_disk &&
				left?.track_number_on_disk == right?.track_number_on_disk
			)
		} areInOrder: {
			guard let right = $1.info else { return true }
			guard let left = $0.info else { return false }
			return Self.__precedes_numerically(strict: false, left, right)
		}
		return sorted.map { $0.song }
	}
	static func precedesNumerically(
		strict: Bool,
		_ left: MKSong, _ right: MKSong
	) -> Bool {
		let leftDisc = left.discNumber
		let rightDisc = right.discNumber
		guard leftDisc == rightDisc else {
			guard let rightDisc else { return true }
			guard let leftDisc else { return false }
			return leftDisc < rightDisc
		}
		
		let rightTrack = right.trackNumber
		let leftTrack = left.trackNumber
		guard leftTrack == rightTrack else {
			guard let rightTrack else { return true }
			guard let leftTrack else { return false }
			return leftTrack < rightTrack
		}
		
		guard strict else { return true }
		
		let leftTitle = left.title
		let rightTitle = right.title
		guard leftTitle == rightTitle else {
			return leftTitle.precedesInFinder(rightTitle)
		}
		
		return left.id.rawValue < right.id.rawValue
	}
	static func __precedes_numerically(
		strict: Bool,
		_ left: some InfoSong, _ right: some InfoSong
	) -> Bool {
		let leftDisc = left.disc_number_on_disk
		let rightDisc = right.disc_number_on_disk
		guard leftDisc == rightDisc else {
			return leftDisc < rightDisc
		}
		
		let leftTrack = left.track_number_on_disk
		let rightTrack = right.track_number_on_disk
		guard leftTrack == rightTrack else {
			guard rightTrack != 0 else { return true }
			guard leftTrack != 0 else { return false }
			return leftTrack < rightTrack
		}
		
		guard strict else { return true }
		
		let leftTitle = left.title_on_disk
		let rightTitle = right.title_on_disk
		guard leftTitle == rightTitle else {
			guard let rightTitle else { return true }
			guard let leftTitle else { return false }
			return leftTitle.precedesInFinder(rightTitle)
		}
		
		return left.id_song < right.id_song
	}
}

// MARK: - Title

extension String {
	// Don’t sort `String`s by `<`. That puts all capital letters before all lowercase letters, meaning “Z” comes before “a”.
	func precedesInFinder(_ other: Self) -> Bool {
		let comparisonResult = localizedStandardCompare(other) // The comparison method that the Finder uses
		switch comparisonResult {
			case .orderedAscending: return true
			case .orderedSame: return true
			case .orderedDescending: return false
		}
	}
}
