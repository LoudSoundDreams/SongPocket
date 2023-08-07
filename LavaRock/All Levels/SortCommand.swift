//
//  SortCommand.swift
//  LavaRock
//
//  Created by h on 2022-04-22.
//

import UIKit
import CoreData

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
			case .song_track: return UIImage(systemName: "number")
			case .song_added: return UIImage(systemName: "clock")
		}
	}
	
	func createMenuElement(
		enabled: Bool,
		handler: @escaping () -> Void
	) -> UIMenuElement {
		return UIDeferredMenuElement.uncached({ useMenuElements in
			let action = UIAction(
				title: localizedName(),
				image: uiImage()
			) { _ in handler() }
			if !enabled {
				action.attributes.formUnion(.disabled)
			}
			useMenuElements([action])
		})
	}
	
	func apply(
		onOrderedIndices: [Int],
		in allItems: [NSManagedObject]
	) -> [NSManagedObject] {
		// Get just the items to sort, and get them sorted in a separate `Array`.
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
			case .random:
				return items.inAnyOtherOrder()
				
			case .reverse:
				return items.reversed()
				
				// Sort stably! Multiple items with the same name, disc number, or whatever property we’re sorting by should stay in the same order.
				// Use `sortedMaintainingOrderWhen` for convenience.
				
			case .folder_name:
				guard let folders = items as? [Collection] else {
					return items
				}
				return folders.sortedMaintainingOrderWhen {
					$0.title == $1.title
				} areInOrder: {
					let leftTitle = $0.title ?? ""
					let rightTitle = $1.title ?? ""
					return leftTitle.precedesAlphabeticallyFinderStyle(rightTitle)
				}
				
			case .album_released:
				guard let albums = items as? [Album] else {
					return items
				}
				return albums.sortedMaintainingOrderWhen {
					$0.releaseDateEstimate == $1.releaseDateEstimate
				} areInOrder: {
					$0.precedesByNewestFirst($1)
				}
				
			case .song_track:
				guard let songs = items as? [Song] else {
					return items
				}
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
				
			case .song_added:
				guard let songs = items as? [Song] else {
					return items
				}
				let songsAndInfos = songs.map {
					(song: $0,
					 info: $0.songInfo())
				}
				let sorted = songsAndInfos.sortedMaintainingOrderWhen {
					left, right in
					return left.info?.dateAddedOnDisk == right.info?.dateAddedOnDisk
				} areInOrder: {
					guard
						let left = $0.info,
						let right = $1.info
					else {
						return true
					}
					return left.dateAddedOnDisk > right.dateAddedOnDisk
				}
				return sorted.map { $0.song }
		}
	}
}
