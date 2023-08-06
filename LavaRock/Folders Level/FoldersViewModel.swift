//
//  FoldersViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-14.
//

import CoreData

struct FoldersViewModel {
	// `LibraryViewModel`
	let context: NSManagedObjectContext
	var prerowCount: Int {
		prerows.count
	}
	var groups: ColumnOfLibraryItems
	
	enum Prerow {
		case createFolder
	}
	var prerows: [Prerow]
}
extension FoldersViewModel: LibraryViewModel {
	static let entityName = "Collection"
	
	func prerowIdentifiers() -> [AnyHashable] {
		return prerows
	}
	
	func allowsSortCommand(
		_ sortCommand: SortCommand,
		forItems items: [NSManagedObject]
	) -> Bool {
		switch sortCommand {
			case .random, .reverse: return true
			case .album_released, .song_track, .song_added: return false
			case .folder_name:
				return true
		}
	}
	
	func updatedWithFreshenedData() -> Self {
		return Self(
			context: context,
			prerows: prerows)
	}
}
extension FoldersViewModel {
	init(
		context: NSManagedObjectContext,
		prerows: [Prerow]
	) {
		self.context = context
		self.prerows = prerows
		
		groups = [
			FoldersOrAlbumsGroup(
				entityName: Self.entityName,
				container: nil,
				context: context)
		]
	}
	
	func folderNonNil(atRow: Int) -> Collection {
		return itemNonNil(atRow: atRow) as! Collection
	}
	
	enum RowCase {
		case prerow(Prerow)
		case folder
	}
	func rowCase(for indexPath: IndexPath) -> RowCase {
		let row = indexPath.row
		if row < prerowCount {
			return .prerow(prerows[row])
		} else {
			return .folder
		}
	}
	
	func numberOfRows() -> Int {
		let group = libraryGroup()
		return prerowCount + group.items.count
	}
	
	private func updatedWithItemsInOnlyGroup(_ newItems: [NSManagedObject]) -> Self {
		var twin = self
		twin.groups[0].setItems(newItems)
		return twin
	}
	
	// MARK: - Renaming
	
	func renameAndReturnDidChangeTitle(
		atRow: Int,
		proposedTitle: String?
	) -> Bool {
		guard
			let proposedTitle = proposedTitle,
			proposedTitle != ""
		else {
			return false
		}
		let newTitle = proposedTitle.truncated(toMaxLength: 256) // In case the user entered a dangerous amount of text
		
		let folder = folderNonNil(atRow: atRow)
		let oldTitle = folder.title
		folder.title = newTitle
		return oldTitle != folder.title
	}
	
	// MARK: - “Move albums” sheet
	
	static let indexOfNewFolder = 0
	
	func updatedAfterCreating() -> Self {
		let newFolder = Collection(context: context)
		newFolder.title = LRString.untitledFolder
		// When we call `setItemsAndMoveRows`, the property observer will set each `Collection.index` for us.
		
		var newItems = libraryGroup().items
		newItems.insert(newFolder, at: Self.indexOfNewFolder)
		
		var twin = updatedWithItemsInOnlyGroup(newItems)
		twin.prerows = []
		return twin
	}
	
	func updatedAfterDeletingNewFolder() -> Self {
		let newItems = itemsAfterDeletingNewFolder()
		
		var twin = updatedWithItemsInOnlyGroup(newItems)
		twin.prerows = [.createFolder]
		return twin
	}
	
	private func itemsAfterDeletingNewFolder() -> [NSManagedObject] {
		let oldItems = libraryGroup().items
		guard
			let folder = oldItems[Self.indexOfNewFolder] as? Collection,
			folder.isEmpty()
		else {
			return oldItems
		}
		
		context.delete(folder)
		
		var newItems = libraryGroup().items
		newItems.remove(at: Self.indexOfNewFolder)
		return newItems
	}
}
