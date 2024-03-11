//
//  SongsViewModel.swift
//  SongsViewModel
//
//  Created by h on 2021-08-14.
//

import CoreData

struct SongsViewModel {
	static let prerowCount = 1
	let album: Album?
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var groups: [LibraryGroup]
}
extension SongsViewModel: LibraryViewModel {
	func itemIndex(forRow row: Int) -> Int {
		return row - Self.prerowCount
	}
	func rowsForAllItems() -> [Int] {
		guard !isEmpty() else {
			return []
		}
		return libraryGroup().items.indices.map { 
			Self.prerowCount + $0
		}
	}
	func row(forItemIndex itemIndex: Int) -> Int {
		return Self.prerowCount + itemIndex
	}
	
	// Similar to counterpart in `AlbumsViewModel`.
	func updatedWithFreshenedData() -> Self {
		let freshenedAlbum: Album? = {
			// WARNING: You must check this, or the initializer will create groups with no items.
			guard let album, !album.wasDeleted() else {
				return nil
			}
			return album
		}()
		return Self(
			album: freshenedAlbum,
			context: context)
	}
	
	func rowIdentifiers() -> [AnyHashable] {
		let itemRowIDs = groups[0].items.map {
			AnyHashable($0.objectID)
		}
		return [42] + itemRowIDs
	}
}
extension SongsViewModel {
	init(
		album: Album?,
		context: NSManagedObjectContext
	) {
		self.album = album
		self.context = context
		
		guard let album else {
			groups = []
			return
		}
		
		groups = [
			SongsGroup(
				album: album,
				context: context)
		]
	}
}
