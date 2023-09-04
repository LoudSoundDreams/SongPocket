//
//  AlbumsViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import CoreData

struct AlbumsViewModel {
	let folder: Collection?
	
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var groups: ColumnOfLibraryItems
}
extension AlbumsViewModel: LibraryViewModel {
	func prerowCount() -> Int { return 0 }
	func prerowIdentifiers() -> [AnyHashable] { return [] }
	
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
			folder: freshenedFolder,
			context: context)
	}
}
extension AlbumsViewModel {
	init(
		folder: Collection?,
		context: NSManagedObjectContext
	) {
		self.folder = folder
		
		self.context = context
		guard let folder else {
			groups = []
			return
		}
		groups = [
			AlbumsGroup(
				folder: folder,
				context: context)
		]
	}
	
	func albumNonNil(atRow: Int) -> Album {
		return itemNonNil(atRow: atRow) as! Album
	}
	
	// MARK: - Organizing
	
	func allowsAutoMove(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		var subjectedRows: [Int] = selectedIndexPaths.map { $0.row }
		if subjectedRows.isEmpty {
			subjectedRows = rowsForAllItems()
		}
		let albums = subjectedRows.map { albumNonNil(atRow: $0) }
		
		// Return `true` if we can move any album to either a new collection or another collection with the same title
		for album in albums {
			let targetTitle = album.albumArtistFormatted()
			if targetTitle != album.container?.title {
				return true
			}
		}
		let existingByTitle: [String: [Collection]] = {
			let all = Collection.allFetched(sorted: false, context: context)
			return Dictionary(grouping: all) { $0.title! }
		}()
		for album in albums {
			let targetTitle = album.albumArtistFormatted() // Must match above
			guard let existingTargets = existingByTitle[targetTitle] else { continue }
			if let _ = existingTargets.first(where: { existingCollection in
				existingCollection != album.container!
			}) {
				return true
			}
		}
		return false
	}
	
	// MARK: - “Move albums” sheet
	
	func updatedAfterInserting(
		albumsWith albumIDs: [NSManagedObjectID]
	) -> Self {
		let group = libraryGroup()
		let destination = group.container as! Collection
		
		destination.unsafe_InsertAlbums_WithoutDeleteOrReindexSources(
			atIndex: 0,
			albumIDs: albumIDs,
			possiblyToSame: true,
			via: context)
		context.deleteEmptyCollections()
		
		return AlbumsViewModel(
			folder: folder,
			context: context)
	}
}
