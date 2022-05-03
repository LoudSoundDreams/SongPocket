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
			guard let representative = (container as? Album)?.representativeSongMetadatum() else {
				return nil
			}
			let metadata: [SongMetadatum] = items.compactMap { ($0 as? Song)?.metadatum() }
			// At the least, reserve the width of 2 digits (plus an interpunct, if appropriate).
			// At the most, reserve the width of 4 digits plus an interpunct.
			if representative.shouldShowDiscNumber {
				var mostDigits = "00"
				for metadatum in metadata {
					let discAndTrack = ""
					+ metadatum.discNumberFormatted()
					+ (metadatum.trackNumberFormattedOptional() ?? "")
					if discAndTrack.count >= 4 {
						return LocalizedString.interpunct + "0000"
					}
					if discAndTrack.count > mostDigits.count {
						mostDigits = discAndTrack
					}
				}
				return LocalizedString.interpunct + mostDigits
			} else {
				var mostDigits = "00"
				for metadatum in metadata {
					let track = metadatum.trackNumberFormattedOptional() ?? ""
					if track.count >= 4 {
						return "0000"
					}
					if track.count > mostDigits.count {
						mostDigits = track
					}
				}
				return String(mostDigits)
			}
		}()
	}
}
