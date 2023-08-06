//
//  AlbumsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import CoreData

enum ParentFolder {
	case exists(Collection)
	case deleted(Collection)
}

struct AlbumsViewModel {
	let parentFolder: ParentFolder
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var prerowCount: Int {
		prerows.count
	}
	var groups: ColumnOfLibraryItems
	
	enum Prerow {
		case moveHere
	}
	var prerows: [Prerow]
}
extension AlbumsViewModel: LibraryViewModel {
	static let entityName = "Album"
	
	func bigTitle() -> String {
		switch parentFolder {
			case
					.exists(let folder),
					.deleted(let folder):
				return folder.title ?? ""
		}
	}
	
	func prerowIdentifiers() -> [AnyHashable] {
		return prerows
	}
	
	func allowsSortCommand(
		_ sortCommand: SortCommand,
		forItems items: [NSManagedObject]
	) -> Bool {
		switch sortCommand {
			case .random, .reverse: return true
			case .folder_name, .song_added, .song_track: return false
			case .album_released:
				guard let albums = items as? [Album] else {
					return false
				}
				return albums.contains { $0.releaseDateEstimate != nil }
		}
	}
	
	// Similar to counterpart in `SongsViewModel`.
	func updatedWithFreshenedData() -> Self {
		let freshenedParent: ParentFolder = {
			switch parentFolder {
				case .exists(let folder):
					if folder.wasDeleted() { // WARNING: You must check this, or the initializer will create groups with no items.
						return .deleted(folder)
					} else {
						return .exists(folder)
					}
				case .deleted(let folder):
					return .deleted(folder)
			}
		}()
		return Self(
			context: context,
			parentFolder: freshenedParent,
			prerows: prerows)
	}
}
extension AlbumsViewModel {
	init(
		context: NSManagedObjectContext,
		parentFolder: ParentFolder,
		prerows: [Prerow]
	) {
		self.context = context
		self.parentFolder = parentFolder
		self.prerows = prerows
		
		// Check `viewContainer` to figure out which `Album`s to show.
		let containers: [NSManagedObject] = {
			switch parentFolder {
				case .exists(let folder):
					return [folder]
				case .deleted:
					return []
			}}()
		groups = containers.map { container in
			FoldersOrAlbumsGroup(
				entityName: Self.entityName,
				container: container,
				context: context)
		}
	}
	
	func albumNonNil(atRow: Int) -> Album {
		return itemNonNil(atRow: atRow) as! Album
	}
	
	enum RowCase {
		case prerow(Prerow)
		case album
	}
	func rowCase(for indexPath: IndexPath) -> RowCase {
		let row = indexPath.row
		if row < prerowCount {
			return .prerow(prerows[indexPath.row])
		} else {
			return .album
		}
	}
	
	// Similar to counterpart in `SongsViewModel`.
	func numberOfRows() -> Int {
		switch parentFolder {
			case .exists:
				let group = libraryGroup()
				return prerowCount + group.items.count
			case .deleted:
				return 0 // Without `prerowCount`
		}
	}
	
	// MARK: - Organizing
	
	// Returns `true` if the albums to organize have at least 2 different album artists.
	// The “albums to organize” are the selected albums, if any, or all the albums, if this is a specifically opened folder.
	func allowsAutoMove(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		var subjectedRows: [Int] = selectedIndexPaths.map { $0.row }
		if subjectedRows.isEmpty {
			subjectedRows = rowsForAllItems()
		}
		let albums = subjectedRows.map { albumNonNil(atRow: $0) }
		
		return albums.contains {
			let titleOfDestination = $0.albumArtistFormatted()
			return titleOfDestination != $0.container?.title
		}
	}
	
	// MARK: - “Move albums” sheet
	
	func updatedAfterMoving(
		albumsWith albumIDs: [NSManagedObjectID]
	) -> Self {
		let group = libraryGroup()
		let destination = group.container as! Collection
		
		destination.moveAlbumsToBeginning(
			with: albumIDs,
			possiblyToSame: true,
			via: context)
		
		return AlbumsViewModel(
			context: context,
			parentFolder: parentFolder,
			prerows: [])
	}
}
