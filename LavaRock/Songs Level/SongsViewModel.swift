//
//  SongsViewModel.swift
//  SongsViewModel
//
//  Created by h on 2021-08-14.
//

import CoreData

enum ParentAlbum {
	case exists(Album)
	case deleted(Album)
}

struct SongsViewModel {
	let parentAlbum: ParentAlbum
	
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
		let freshenedParentAlbum: ParentAlbum = {
			switch parentAlbum {
				case .exists(let album):
					if album.wasDeleted() { // WARNING: You must check this, or the initializer will create groups with no items.
						return .deleted(album)
					} else {
						return .exists(album)
					}
				case .deleted(let album):
					return .deleted(album)
			}
		}()
		return Self(
			parentAlbum: freshenedParentAlbum,
			context: context)
	}
}
extension SongsViewModel {
	init(
		parentAlbum: ParentAlbum,
		context: NSManagedObjectContext
	) {
		self.parentAlbum = parentAlbum
		self.context = context
		
		// Check `viewContainer` to figure out which `Song`s to show.
		let containers: [NSManagedObject] = {
			switch parentAlbum {
				case .exists(let album):
					return [album]
				case .deleted:
					return []
			}}()
		groups = containers.map { container in
			SongsGroup(
				entityName: Self.entityName,
				container: container,
				context: context)
		}
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
	
	// Similar to counterpart in `AlbumsViewModel`.
	func numberOfRows() -> Int {
		switch parentAlbum {
			case .exists:
				let group = libraryGroup()
				return prerowCount + group.items.count
			case .deleted:
				return 0 // Without `prerowCount`
		}
	}
}
