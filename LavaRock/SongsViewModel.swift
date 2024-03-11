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
	
	let album: Album?
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var groups: ColumnOfLibraryItems
}
extension SongsViewModel: LibraryViewModel {
	func prerowCount() -> Int { return 1 }
	func prerowIdentifiers() -> [AnyHashable] {
		return [Prerow.albumInfo]
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
		if indexPath.row < prerowCount() {
			return .prerow(.albumInfo)
		} else {
			return .song
		}
	}
}
