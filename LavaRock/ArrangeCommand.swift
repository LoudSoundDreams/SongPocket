// 2022-04-22

import UIKit
import CoreData
import MusicKit

enum ArrangeCommand {
	case random
	case reverse
	
	case album_recentlyAdded
	case album_newest
	case album_artist
	
	case song_track
	
	@MainActor func createMenuElement(
		enabled: Bool,
		handler: @escaping () -> Void
	) -> UIMenuElement {
		return UIDeferredMenuElement.uncached { useMenuElements in
			// Runs each time the button presents the menu
			let action = UIAction(
				title: { switch self {
					case .random: return InterfaceText.random
					case .reverse: return InterfaceText.reverse
					case .album_recentlyAdded: return InterfaceText.recentlyAdded
					case .album_newest: return InterfaceText.newest
					case .album_artist: return InterfaceText.artist
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
					case .album_recentlyAdded: return "clock"
					case .album_newest: return "sparkles"
					case .album_artist: return "music.mic"
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
				
			case .album_recentlyAdded:
				guard let albums = items as? [Album] else { return items }
				let albumsAndDates = albums.map {
					(
						album: $0,
						dateFirstAdded: $0.songs(sorted: false)
							.compactMap { $0.songInfo()?.dateAddedOnDisk }
							.reduce(into: Date.now) { oldestSoFar, dateAdded in
								oldestSoFar = min(oldestSoFar, dateAdded)
							}
					)
				}
				let sorted = albumsAndDates.sorted { leftTuple, rightTuple in
					leftTuple.dateFirstAdded > rightTuple.dateFirstAdded
				}
				return sorted.map { $0.album }
			case .album_newest:
				guard let albums = items as? [Album] else { return items }
				return albums.sortedMaintainingOrderWhen {
					$0.releaseDateEstimate == $1.releaseDateEstimate
				} areInOrder: {
					$0.precedesByNewestFirst($1)
				}
			case .album_artist:
				guard let albums = items as? [Album] else { return items }
				let albumsAndArtists: [(album: Album, artist: String?)] = albums.map {(
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
