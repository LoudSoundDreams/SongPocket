//
//  SongsViewModel.swift
//  SongsViewModel
//
//  Created by h on 2021-08-14.
//

import CoreData

struct SongsViewModel {
	enum Prerow {
		case albumInfo
	}
	private static let prerows: [Prerow] = [
		.albumInfo,
	]
	
	let album: Album?
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var groups: ColumnOfLibraryItems
}
extension SongsViewModel: LibraryViewModel {
	func prerowCount() -> Int {
		return Self.prerows.count
	}
	func prerowIdentifiers() -> [AnyHashable] {
		return Self.prerows
	}
	
	// Similar to counterpart in `AlbumsViewModel`.
	func updatedWithFreshenedData() -> Self {
		let freshenedAlbum: Album? = {
			guard
				let album,
				!album.wasDeleted() // WARNING: You must check this, or the initializer will create groups with no items.
			else {
				return nil
			}
			return album
		}()
		return Self(
			album: freshenedAlbum,
			context: context)
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
	
	enum RowCase {
		case prerow(Prerow)
		case song
	}
	func rowCase(for indexPath: IndexPath) -> RowCase {
		let row = indexPath.row
		if row < prerowCount() {
			let associatedValue = Self.prerows[row]
			return .prerow(associatedValue)
		} else {
			return .song
		}
	}
}
