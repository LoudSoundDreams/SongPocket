// 2022-04-22

import UIKit

enum AlbumOrder {
	case random
	case reverse
	
	case recentlyAdded
	case recentlyReleased
	case artist
	case title
	
	@MainActor func newUIAction(handler: @escaping () -> Void) -> UIAction {
		return UIAction(
			title: { switch self {
				case .random: return InterfaceText.random
				case .reverse: return InterfaceText.reverse
				case .recentlyAdded: return InterfaceText.recentlyAdded
				case .recentlyReleased: return InterfaceText.recentlyReleased
				case .artist: return InterfaceText.artist
				case .title: return InterfaceText.title
			}}(),
			image: UIImage(systemName: { switch self {
				case .random:
					switch Int.random(in: 1...6) {
						case 1: return "die.face.1"
						case 2: return "die.face.2"
						case 3: return "die.face.3"
						case 4: return "die.face.4"
						case 5: return "die.face.5"
						default: return "die.face.6"
					}
				case .reverse: return "arrow.up.and.down"
				case .recentlyAdded: return "plus.square"
				case .recentlyReleased: return "calendar"
				case .artist: return "music.mic"
				case .title: return "character"
			}}()),
			handler: { _ in handler() })
	}
	
	@MainActor func reindex(_ inOriginalOrder: [Album]) {
		let replaceAt: [Int64] = inOriginalOrder.map { $0.index }
		let arranged: [Album] = { switch self {
			case .random: return inOriginalOrder.inAnyOtherOrder()
			case .reverse: return inOriginalOrder.reversed()
				
				// Sort stably: keep elements in the same order if they have the same release date, artist, or so on.
				
			case .recentlyAdded:
				// 10,000 albums takes 11.4s in 2024.
				let now = Date.now // Keeps `Album`s without date added at the beginning, maintaining their current order.
				let albumsAndFirstAdded: [(album: Album, firstAdded: Date)] = inOriginalOrder.map { album in (
					album: album,
					firstAdded: {
						let mkSongs = Crate.shared.mkSection(albumID: album.albumPersistentID)?.items ?? [] // As of iOS 17.6 developer beta 2, `MusicKit.Album.libraryAddedDate` reports the latest date you added one of its songs, not the earliest. That matches how the Apple Music app sorts its Library tab’s Recently Added section, but doesn’t match how it sorts playlists by “Recently Added”, which is actually by date created.
						// I prefer using date created, because it’s stable: that’s the order we naturally get by adding new albums at the top when we first import them, regardless of when that is.
						return Album.dateCreated(mkSongs) ?? now
					}()
				)}
				let sorted = albumsAndFirstAdded.sortedStably { // 10,000 albums takes 41ms in 2024.
					$0.firstAdded == $1.firstAdded // MusicKit’s granularity is 1 second; we can’t meaningfully compare items added within the same second.
				} areInOrder: {
					$0.firstAdded > $1.firstAdded
				}
				return sorted.map { $0.album }
			case .recentlyReleased:
				let albumsAndReleaseDates: [(album: Album, releaseDate: Date?)] = inOriginalOrder.map {(
					album: $0,
					releaseDate: Crate.shared.mkSection(albumID: $0.albumPersistentID)?.releaseDate // As of iOS 17.6 developer beta 2, `MusicKit.Album.releaseDate` nonsensically reports the date of its earliest-released song, not its latest, and `MusicKit.Song.releaseDate` always returns `nil`. At least this matches the date we show in the UI.
				)}
				let sorted = albumsAndReleaseDates.sortedStably {
					$0.releaseDate == $1.releaseDate
				} areInOrder: {
					// Move unknown release date to the end
					guard let rightDate = $1.releaseDate else { return true }
					guard let leftDate = $0.releaseDate else { return false }
					return leftDate > rightDate
				}
				return sorted.map { $0.album }
			case .artist:
				// 10,000 albums takes 30.3s in 2024.
				let albumsAndArtists: [(album: Album, artist: String?)] = inOriginalOrder.map {(
					album: $0,
					artist: Crate.shared.mkSection(albumID: $0.albumPersistentID)?.artistName
				)}
				let sorted = albumsAndArtists.sortedStably {
					$0.artist == $1.artist
				} areInOrder: {
					guard let rightArtist = $1.artist else { return true }
					guard let leftArtist = $0.artist else { return false }
					return leftArtist.precedesInFinder(rightArtist)
				}
				return sorted.map { $0.album }
			case .title:
				let albumsAndTitles: [(album: Album, title: String?)] = inOriginalOrder.map {(
					album: $0,
					title: Crate.shared.mkSection(albumID: $0.albumPersistentID)?.title
				)}
				let sorted = albumsAndTitles.sortedStably {
					$0.title == $1.title
				} areInOrder: {
					guard let rightTitle = $1.title else { return true }
					guard let leftTitle = $0.title else { return false }
					return leftTitle.precedesInFinder(rightTitle)
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
	
	@MainActor func newUIAction(handler: @escaping () -> Void) -> UIAction {
		return UIAction(
			title: { switch self {
				case .random: return InterfaceText.random
				case .reverse: return InterfaceText.reverse
				case .track: return InterfaceText.trackNumber
			}}(),
			image: UIImage(systemName: { switch self {
				case .random:
					switch Int.random(in: 1...6) {
						case 1: return "die.face.1"
						case 2: return "die.face.2"
						case 3: return "die.face.3"
						case 4: return "die.face.4"
						case 5: return "die.face.5"
						default: return "die.face.6"
					}
				case .reverse: return "arrow.up.and.down"
				case .track: return "number"
			}}()),
			handler: { _ in handler() })
	}
	
	@MainActor func reindex(_ inOriginalOrder: [Song]) {
		let replaceAt: [Int64] = inOriginalOrder.map { $0.index }
		let arranged: [Song] = { switch self {
			case .random: return inOriginalOrder.inAnyOtherOrder()
			case .reverse: return inOriginalOrder.reversed()
				
			case .track: return Self.sortedNumerically(strict: false, inOriginalOrder)
		}}()
		arranged.indices.forEach { counter in
			arranged[counter].index = replaceAt[counter]
		}
	}
	
	@MainActor static func sortedNumerically(strict: Bool, _ input: [Song]) -> [Song] {
		let songsAndInfos: [(song: Song, info: (some SongInfo)?)] = input.map {(
			song: $0,
			info: Song.info(mpID: $0.persistentID)
		)}
		let sorted = songsAndInfos.sortedStably {
			let left = $0.info; let right = $1.info
			return (
				left?.discNumberOnDisk == right?.discNumberOnDisk &&
				left?.trackNumberOnDisk == right?.trackNumberOnDisk
			)
		} areInOrder: {
			guard let right = $1.info else { return true }
			guard let left = $0.info else { return false }
			return Self.precedesNumerically(strict: false, left, right)
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
	static func precedesNumerically(
		strict: Bool,
		_ left: some SongInfo, _ right: some SongInfo
	) -> Bool {
		let leftDisc = left.discNumberOnDisk
		let rightDisc = right.discNumberOnDisk
		guard leftDisc == rightDisc else {
			return leftDisc < rightDisc
		}
		
		let leftTrack = left.trackNumberOnDisk
		let rightTrack = right.trackNumberOnDisk
		guard leftTrack == rightTrack else {
			guard rightTrack != 0 else { return true }
			guard leftTrack != 0 else { return false }
			return leftTrack < rightTrack
		}
		
		guard strict else { return true }
		
		let leftTitle = left.titleOnDisk
		let rightTitle = right.titleOnDisk
		guard leftTitle == rightTitle else {
			guard let rightTitle else { return true }
			guard let leftTitle else { return false }
			return leftTitle.precedesInFinder(rightTitle)
		}
		
		return left.songID < right.songID
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
