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
	
	@MainActor func newUIAction(
		handler: @escaping () -> Void
	) -> UIAction {
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
	
	@MainActor func reindex(_ toArrange: [Album]) {
		let replaceAt: [Int64] = toArrange.map { $0.index }
		let arranged: [Album] = { switch self {
			case .random: return toArrange.inAnyOtherOrder()
			case .reverse: return toArrange.reversed()
				
			case .recentlyAdded:
				let albumsAndDates = toArrange.map {(
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
				return toArrange.sortedMaintainingOrderWhen {
					$0.releaseDateEstimate == $1.releaseDateEstimate
				} areInOrder: {
					$0.precedesByNewestFirst($1)
				}
			case .artist:
				let albumsAndArtists: [(album: Album, artist: String?)] = toArrange.map {(
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
			let arrangedAlbum = arranged[counter]
			let newIndex = replaceAt[counter]
			arrangedAlbum.index = newIndex
		}
	}
}
enum ArrangeCommand {
	case random
	case reverse
	
	case song_track
	
	@MainActor func newMenuElement(
		enabled: Bool,
		handler: @escaping () -> Void
	) -> UIMenuElement {
		return UIDeferredMenuElement.uncached { useMenuElements in
			// Runs each time the button presents the menu
			let action = UIAction(
				title: { switch self {
					case .random: return InterfaceText.random
					case .reverse: return InterfaceText.reverse
					case .song_track: return InterfaceText.trackNumber
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
					case .song_track: return "number"
				}}())
			) { _ in handler() }
			// Disable if appropriate. This must be inside `UIDeferredMenuElement.uncached`. `UIMenu` caches `UIAction.attributes`.
			if !enabled {
				action.attributes.formUnion(.disabled)
			}
			useMenuElements([action])
		}
	}
	
	@MainActor func apply(to items: [NSManagedObject]) -> [NSManagedObject] {
		switch self {
			case .random: return items.inAnyOtherOrder()
			case .reverse: return items.reversed()
				
			case .song_track:
				guard let songs = items as? [Song] else { return items }
				// Actually, return the songs grouped by disc number, and sorted by track number within each disc.
				let songsAndInfos = songs.map { (song: $0, info: $0.songInfo()) }
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
		}
	}
}
