//
//  SongsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import CoreData

struct SongsViewModel {
	static let prerowCount = 1
	let album: Album
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var group: LibraryGroup
}
extension SongsViewModel: LibraryViewModel {
	func itemIndex(forRow row: Int) -> Int {
		return row - Self.prerowCount
	}
	func rowsForAllItems() -> [Int] {
		guard !isEmpty() else {
			return []
		}
		return group.items.indices.map {
			Self.prerowCount + $0
		}
	}
	func row(forItemIndex itemIndex: Int) -> Int {
		return Self.prerowCount + itemIndex
	}
	
	// Similar to counterpart in `AlbumsViewModel`.
	func updatedWithFreshenedData() -> Self {
		return Self(album: album, context: context)
	}
	
	func rowIdentifiers() -> [AnyHashable] {
		let itemRowIDs = group.items.map {
			AnyHashable($0.objectID)
		}
		return [42] + itemRowIDs
	}
}
extension SongsViewModel {
	init(
		album: Album,
		context: NSManagedObjectContext
	) {
		self.album = album
		self.context = context
		group = SongsGroup(album: album, context: context)
	}
}
