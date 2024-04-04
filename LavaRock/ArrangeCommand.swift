// 2022-04-22

import UIKit
import CoreData

enum ArrangeCommand: CaseIterable {
	case random
	case reverse
	
	case album_newest
	case album_oldest
	
	case song_track
	
	func localizedName() -> String {
		switch self {
			case .random: return LRString.random
			case .reverse: return LRString.reverse
			case .album_newest: return LRString.newest
			case .album_oldest: return LRString.oldest
			case .song_track: return LRString.trackNumber
		}
	}
	
	@MainActor func createMenuElement(
		enabled: Bool,
		handler: @escaping () -> Void
	) -> UIMenuElement {
		return UIDeferredMenuElement.uncached({ useMenuElements in
			// Runs each time the button presents the menu
			let action = UIAction(
				title: localizedName(),
				image: UIImage(systemName: sfSymbolName)
			) { _ in handler() }
			// Disable if appropriate. This must be inside `UIDeferredMenuElement.uncached`. `UIMenu` caches `UIAction.attributes`.
			if !enabled {
				action.attributes.formUnion(.disabled)
			}
			useMenuElements([action])
		})
	}
	private var sfSymbolName: String {
		switch self {
			case .random:
				switch Int.random(in: 1...6) {
					case 1: return "die.face.1"
					case 2: return "die.face.2"
					case 4: return "die.face.4"
					case 5: return "die.face.5"
					case 6: return "die.face.6"
					default: return "die.face.3" // Most recognizable. If we weren’t doing this little joke, we’d use this icon every time. (Second–most recognizable is 6.)
				}
			case .reverse: return "arrow.up.and.down"
			case .album_newest: return "hourglass.bottomhalf.filled"
			case .album_oldest: return "hourglass.tophalf.filled"
			case .song_track: return "number"
		}
	}
	
	func apply(
		onOrderedIndices: [Int],
		in allItems: [NSManagedObject]
	) -> [NSManagedObject] {
		// Get just the items to sort, and get them sorted in a separate array.
		let sortedItemsOnly: [NSManagedObject] = {
			let toSort = onOrderedIndices.map { allItems[$0] }
			return self.apply(to: toSort)
		}()
		
		var result = allItems
		result.replace(
			atIndices: onOrderedIndices,
			withElements: sortedItemsOnly)
		return result
	}
	private func apply(to items: [NSManagedObject]) -> [NSManagedObject] {
		switch self {
			case .random: return items.inAnyOtherOrder()
			case .reverse: return items.reversed()
				
			case .album_newest:
				guard let albums = items as? [Album] else { return items }
				return albums.sortedMaintainingOrderWhen {
					$0.releaseDateEstimate == $1.releaseDateEstimate
				} areInOrder: {
					$0.precedesByNewestFirst($1)
				}
			case .album_oldest:
				guard let albums = items as? [Album] else { return items }
				return albums.sortedMaintainingOrderWhen {
					$0.releaseDateEstimate == $1.releaseDateEstimate
				} areInOrder: {
					$0.precedesByOldestFirst($1)
				}
				
			case .song_track:
				guard let songs = items as? [Song] else { return items }
				// Actually, return the songs grouped by disc number, and sorted by track number within each disc.
				let songsAndInfos = songs.map {
					(song: $0,
					 info: $0.songInfo())
				}
				let sorted = songsAndInfos.sortedMaintainingOrderWhen {
					let left = $0.info
					let right = $1.info
					return left?.discNumberOnDisk == right?.discNumberOnDisk
					&& left?.trackNumberOnDisk == right?.trackNumberOnDisk
				} areInOrder: {
					guard
						let left = $0.info,
						let right = $1.info
					else {
						return true
					}
					return left.precedesByTrackNumber(right)
				}
				return sorted.map { $0.song }
		}
	}
}
