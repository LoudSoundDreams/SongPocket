//
//  AlbumsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import CoreData

struct AlbumsViewModel {
	enum Prerow {
		case moveHere
	}
	var prerows: [Prerow]
	
	let folder: Collection?
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var groups: ColumnOfLibraryItems
}
extension AlbumsViewModel: LibraryViewModel {
	static let entityName = "Album"
	
	func prerowCount() -> Int {
		return prerows.count
	}
	func prerowIdentifiers() -> [AnyHashable] {
		return prerows
	}
	
	// Similar to counterpart in `SongsViewModel`.
	func updatedWithFreshenedData() -> Self {
		let freshenedFolder: Collection? = {
			guard
				let folder,
				!folder.wasDeleted() // WARNING: You must check this, or the initializer will create groups with no items.
			else {
				return nil
			}
			return folder
		}()
		return Self(
			prerows: prerows,
			folder: freshenedFolder,
			context: context)
	}
}
extension AlbumsViewModel {
	init(
		prerows: [Prerow],
		folder: Collection?,
		context: NSManagedObjectContext
	) {
		self.prerows = prerows
		self.folder = folder
		
		self.context = context
		guard let folder else {
			groups = []
			return
		}
		groups = [
			FoldersOrAlbumsGroup(
				entityName: Self.entityName,
				container: folder,
				context: context)
		]
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
		if row < prerowCount() {
			return .prerow(prerows[row])
		} else {
			return .album
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
	
	func updatedAfterInserting(
		albumsWith albumIDs: [NSManagedObjectID]
	) -> Self {
		let group = libraryGroup()
		let destination = group.container as! Collection
		
		destination.moveAlbumsToBeginning(
			with: albumIDs,
			possiblyToSame: true,
			via: context)
		
		return AlbumsViewModel(
			prerows: [],
			folder: folder,
			context: context)
	}
}
