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
				let albumsAndFirstAdded: [(album: Album, firstAdded: Date)] = inOriginalOrder.map { albumToSort in (
					album: albumToSort,
					firstAdded: {
						let musicKitSongs = Crate.shared.musicKitSection(albumToSort.albumPersistentID)?.items ?? [] // As of iOS 17.6 developer beta 2, `MusicKit.Album.libraryAddedDate` reports the latest date you added one of its songs, not the earliest. That matches how the Apple Music app sorts its Library tab’s Recently Added section, but doesn’t match how it sorts playlists by “Recently Added”, which is actually by date created.
						// I prefer using date created, meaning the date you first added one of the album’s songs, because that’s what happens naturally when we add new albums at the top when we first see them.
						return musicKitSongs.reduce(into: now) { earliestSoFar, musicKitSong in
							if
								let dateAdded = musicKitSong.libraryAddedDate, // MusicKit’s granularity is 1 second; we can’t meaningfully compare items added within the same second.
								dateAdded < earliestSoFar
							{ earliestSoFar = dateAdded }
						}
					}()
				)}
				let sorted = albumsAndFirstAdded.sorted { $0.firstAdded > $1.firstAdded }
				return sorted.map { $0.album }
			case .recentlyReleased:
				let albumsAndReleaseDates: [(album: Album, releaseDate: Date?)] = inOriginalOrder.map {(
					album: $0,
					releaseDate: Crate.shared.musicKitSection($0.albumPersistentID)?.releaseDate // As of iOS 17.6 developer beta 2, `MusicKit.Album.releaseDate` nonsensically reports the date of its earliest-released song, not its latest, and `MusicKit.Song.releaseDate` always returns `nil`. At least this matches the date we show in the UI.
				)}
				let sorted = albumsAndReleaseDates.sortedMaintainingOrderWhen {
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
					artist: Crate.shared.musicKitSection($0.albumPersistentID)?.artistName
				)}
				let sorted = albumsAndArtists.sortedMaintainingOrderWhen {
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
					title: Crate.shared.musicKitSection($0.albumPersistentID)?.title
				)}
				let sorted = albumsAndTitles.sortedMaintainingOrderWhen {
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
				
			case .track:
				// Actually, return the songs grouped by disc number, and sorted by track number within each disc.
				let songsAndInfos = inOriginalOrder.map { (song: $0, info: $0.songInfo()) }
				let sorted = songsAndInfos.sortedMaintainingOrderWhen {
					let left = $0.info
					let right = $1.info
					return (
						left?.discNumberOnDisk == right?.discNumberOnDisk
						&& left?.trackNumberOnDisk == right?.trackNumberOnDisk
					)
				} areInOrder: {
					guard let left = $0.info, let right = $1.info else { return true }
					return left.precedesNumerically(inSameAlbum: right, shouldResortToTitle: false)
				}
				return sorted.map { $0.song }
		}}()
		arranged.indices.forEach { counter in
			arranged[counter].index = replaceAt[counter]
		}
	}
}

// MARK: - Track number

extension SongInfo {
	// Behavior is undefined if you compare with a `SongInfo` from a different album.
	func precedesNumerically(
		inSameAlbum other: SongInfo,
		shouldResortToTitle: Bool
	) -> Bool {
		// Sort by disc number
		let myDisc = discNumberOnDisk
		let otherDisc = other.discNumberOnDisk
		guard myDisc == otherDisc else {
			return myDisc < otherDisc
		}
		
		let myTrack = trackNumberOnDisk
		let otherTrack = other.trackNumberOnDisk
		
		if shouldResortToTitle {
			guard myTrack != otherTrack else {
				// Sort by song title
				let myTitle = titleOnDisk ?? ""
				let otherTitle = other.titleOnDisk ?? ""
				return myTitle.precedesInFinder(otherTitle)
			}
		} else {
			// At this point, leave elements in the same order if they both have no track number, or the same track number.
			// However, as of iOS 14.7, when using `sorted(by:)`, returning `true` here doesn’t always keep the elements in the same order. Call this method in `sortedMaintainingOrderWhen` to guarantee stable sorting.
			guard myTrack != otherTrack else { return true }
		}
		
		// Move unknown track number to the end
		guard otherTrack != type(of: other).unknownTrackNumber else { return true }
		guard myTrack != Self.unknownTrackNumber else { return false }
		
		return myTrack < otherTrack
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
