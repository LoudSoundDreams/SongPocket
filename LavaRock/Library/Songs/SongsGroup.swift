//
//  SongsGroup.swift
//  LavaRock
//
//  Created by h on 2021-07-02.
//

import CoreData

struct SongsGroup {
	// `LibraryGroup`
	let container: NSManagedObject?
	private(set) var items: [NSManagedObject] {
		didSet {
			items.enumerated().forEach { (currentIndex, libraryItem) in
				libraryItem.setValue(
					Int64(currentIndex),
					forKey: "Index")
			}
		}
	}
	
	private(set) var spacerTrackNumberText: String? = nil
}
extension SongsGroup: LibraryGroup {
	mutating func setItems(_ newItems: [NSManagedObject]) {
		items = newItems
	}
	
	init(
		entityName: String,
		container: NSManagedObject?,
		context: NSManagedObjectContext
	) {
		items = Self.itemsFetched( // Doesn’t trigger the property observer
			entityName: entityName,
			container: container,
			context: context)
		self.container = container
		
		spacerTrackNumberText = {
			guard let representative = (container as? Album)?.representativeSongInfo() else {
				return nil
			}
			let infos: [SongInfo] = items.compactMap { ($0 as? Song)?.songInfo() }
			// At minimum, reserve the width of 2 digits, plus an interpunct if appropriate.
			// At maximum, reserve the width of 4 digits plus an interpunct.
			if representative.shouldShowDiscNumber {
				var widestText = "00"
				for info in infos {
					let discAndTrack = ""
					+ info.discNumberFormatted()
					+ (info.trackNumberFormattedOptional() ?? "")
					if discAndTrack.count >= 4 {
						return LRString.interpunct + "0000"
					}
					if discAndTrack.count > widestText.count {
						widestText = discAndTrack
					}
				}
				return LRString.interpunct + widestText
			} else {
				var widestText = "00"
				for info in infos {
					let track = info.trackNumberFormattedOptional() ?? ""
					if track.count >= 4 {
						return "0000"
					}
					if track.count > widestText.count {
						widestText = track
					}
				}
				return String(widestText)
			}
		}()
	}
}
