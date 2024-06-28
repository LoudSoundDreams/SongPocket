// 2022-04-22

import UIKit
import CoreData
import MusicKit

enum AlbumOrder {
	case random
	case reverse
	
	case recentlyAdded
	case newest
	case artist
	
	@MainActor func newUIAction(handler: @escaping () -> Void) -> UIAction {
		return UIAction(
			title: { switch self {
				case .random: return InterfaceText.random
				case .reverse: return InterfaceText.reverse
				case .recentlyAdded: return InterfaceText.recentlyAdded
				case .newest: return InterfaceText.newest
				case .artist: return InterfaceText.artist
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
				case .recentlyAdded: return "clock"
				case .newest: return "sparkles"
				case .artist: return "music.mic"
			}}()),
			handler: { _ in handler() })
	}
	
	@MainActor func reindex(_ inOriginalOrder: [Album]) {
		let replaceAt: [Int64] = inOriginalOrder.map { $0.index }
		let arranged: [Album] = { switch self {
			case .random: return inOriginalOrder.inAnyOtherOrder()
			case .reverse: return inOriginalOrder.reversed()
				
			case .recentlyAdded:
				let albumsAndDates = inOriginalOrder.map {(
					album: $0,
					dateFirstAdded:
						$0.songs(sorted: false)
						.compactMap { $0.songInfo()?.dateAddedOnDisk }
						.reduce(into: Date.now) { oldestSoFar, dateAdded in
							oldestSoFar = min(oldestSoFar, dateAdded)
						}
				)}
				let sorted = albumsAndDates.sorted { leftTuple, rightTuple in
					leftTuple.dateFirstAdded > rightTuple.dateFirstAdded
				}
				return sorted.map { $0.album }
			case .newest:
				return inOriginalOrder.sortedMaintainingOrderWhen {
					$0.releaseDateEstimate == $1.releaseDateEstimate
				} areInOrder: {
					$0.precedesByNewestFirst($1)
				}
			case .artist:
				let albumsAndArtists: [(album: Album, artist: String?)] = inOriginalOrder.map {(
					album: $0,
					artist: MusicRepo.shared.musicKitAlbums[MusicItemID(String($0.albumPersistentID))]?.artistName
				)}
				let sorted = albumsAndArtists.sortedMaintainingOrderWhen {
					$0.artist == $1.artist
				} areInOrder: { leftTuple, rightTuple in
					guard let rightArtist = rightTuple.artist else { return true }
					guard let leftArtist = leftTuple.artist else { return false }
					return leftArtist.precedesInFinder(rightArtist)
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
