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
	var numberOfPrerowsPerSection: Int {
		prerowsInEachSection.count
	}
	var groups: ColumnOfLibraryItems
	
	enum Prerow {
		case createFolder
	}
	var prerowsInEachSection: [Prerow]
}
extension FoldersViewModel: LibraryViewModel {
	static let entityName = "Collection"
	
	func bigTitle() -> String {
		return LRString.folders
	}
	
	func prerowIdentifiersInEachSection() -> [AnyHashable] {
		return prerowsInEachSection
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
			prerowsInEachSection: prerowsInEachSection)
	}
}
extension FoldersViewModel {
	init(
		context: NSManagedObjectContext,
		prerowsInEachSection: [Prerow]
	) {
		self.context = context
		self.prerowsInEachSection = prerowsInEachSection
		
		groups = [
			FoldersOrAlbumsGroup(
				entityName: Self.entityName,
				container: nil,
				context: context)
		]
	}
	
	func folderNonNil(at indexPath: IndexPath) -> Collection {
		return itemNonNil(atRow: indexPath.row) as! Collection
	}
	
	enum RowCase {
		case prerow(Prerow)
		case folder
	}
	func rowCase(for indexPath: IndexPath) -> RowCase {
		let row = indexPath.row
		if row < numberOfPrerowsPerSection {
			return .prerow(prerowsInEachSection[row])
		} else {
			return .folder
		}
	}
	
	func numberOfRows() -> Int {
		let group = libraryGroup()
		return numberOfPrerowsPerSection + group.items.count
	}
	
	private func updatedWithItemsInOnlyGroup(_ newItems: [NSManagedObject]) -> Self {
		var twin = self
		twin.groups[0].setItems(newItems)
		return twin
	}
	
	// MARK: - Renaming
	
	func renameAndReturnDidChangeTitle(
		at indexPath: IndexPath,
		proposedTitle: String?
	) -> Bool {
		guard
			let proposedTitle = proposedTitle,
			proposedTitle != ""
		else {
			return false
		}
		let newTitle = proposedTitle.truncated(toMaxLength: 256) // In case the user entered a dangerous amount of text
		
		let folder = folderNonNil(at: indexPath)
		let oldTitle = folder.title
		folder.title = newTitle
		return oldTitle != folder.title
	}
	
	// MARK: - “Move albums” sheet
	
	private static let indexOfNewFolder = 0
	var indexPathOfNewFolder: IndexPath {
		return indexPathFor(itemIndex: Self.indexOfNewFolder)
	}
	
	func updatedAfterCreating() -> Self {
		let newFolder = Collection(context: context)
		newFolder.title = LRString.untitledFolder
		// When we call `setItemsAndMoveRows`, the property observer will set each `Collection.index` for us.
		
		var newItems = libraryGroup().items
		newItems.insert(newFolder, at: Self.indexOfNewFolder)
		
		var twin = updatedWithItemsInOnlyGroup(newItems)
		twin.prerowsInEachSection = []
		return twin
	}
	
	func updatedAfterDeletingNewFolder() -> Self {
		let newItems = itemsAfterDeletingNewFolder()
		
		var twin = updatedWithItemsInOnlyGroup(newItems)
		twin.prerowsInEachSection = [.createFolder]
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
