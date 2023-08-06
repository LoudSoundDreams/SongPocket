//
//  SongsViewModel.swift
//  SongsViewModel
//
//  Created by h on 2021-08-14.
//

import CoreData

struct SongsViewModel {
	let album: Album?
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var prerowCount: Int {
		prerows.count
	}
	var groups: ColumnOfLibraryItems
	
	enum Prerow {
		case coverArt
		case albumInfo
	}
	let prerows: [Prerow] = [
		.coverArt,
		.albumInfo,
	]
}
extension SongsViewModel: LibraryViewModel {
	static let entityName = "Song"
	
	func prerowIdentifiers() -> [AnyHashable] {
		return prerows
	}
	
	func allowsSortCommand(
		_ sortCommand: SortCommand,
		forItems items: [NSManagedObject]
	) -> Bool {
		switch sortCommand {
			case .random, .reverse: return true
			case .folder_name, .album_released: return false
			case
					.song_track,
					.song_added:
				return true
		}
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
				entityName: Self.entityName,
				container: album,
				context: context)
		]
	}
	
	enum RowCase {
		case prerow(Prerow)
		case song
	}
	func rowCase(for indexPath: IndexPath) -> RowCase {
		let row = indexPath.row
		if row < prerowCount {
			let associatedValue = prerows[row]
			return .prerow(associatedValue)
		} else {
			return .song
		}
	}
}
