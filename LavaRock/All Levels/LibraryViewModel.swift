//
//  LibraryViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-12.
//

import CoreData

typealias ColumnOfLibraryItems = [LibraryGroup]
protocol LibraryViewModel {
	static var entityName: String { get }
	
	var context: NSManagedObjectContext { get }
	var prerowCount: Int { get }
	
	var groups: ColumnOfLibraryItems { get set }
	
	func prerowIdentifiers() -> [AnyHashable]
	func allowsSortCommand(
		_ sortCommand: SortCommand,
		forItems items: [NSManagedObject]
	) -> Bool
	func updatedWithFreshenedData() -> Self
}

struct SectionStructure<
	Identifier: Hashable,
	RowIdentifier: Hashable
> {
	let identifier: Identifier
	let rowIdentifiers: [RowIdentifier]
}
extension SectionStructure: Hashable {}
enum SectionID: Hashable {
	case groupWithNoContainer
	case groupWithContainer(NSManagedObjectID)
}
enum RowID: Hashable {
	case prerow(AnyHashable)
	case libraryItem(NSManagedObjectID)
}

extension LibraryViewModel {
	func isEmpty() -> Bool {
		return groups.allSatisfy { group in
			group.items.isEmpty
		}
	}
	
	func sectionStructures() -> [SectionStructure<SectionID, RowID>] {
		return groups.map { group in
			let sectionID: SectionID = {
				guard let containerID = group.container?.objectID else {
					return .groupWithNoContainer
				}
				return .groupWithContainer(containerID)
			}()
			
			let prerowIDs = prerowIdentifiers().map {
				RowID.prerow($0)
			}
			let itemRowIDs = group.items.map { item in
				RowID.libraryItem(item.objectID)
			}
			let rowIDs = prerowIDs + itemRowIDs
			
			return SectionStructure(
				identifier: sectionID,
				rowIdentifiers: rowIDs)
		}
	}
	
	// MARK: - Elements
	
	// WARNING: Never use `LibraryGroup.items[indexPath.row]`. That might return the wrong library item, because `IndexPath`s are offset by `prerowCount`.
	
	func libraryGroup() -> LibraryGroup {
		return groups[0]
	}
	
	func pointsToSomeItem(row: Int) -> Bool {
		guard !isEmpty() else {
			return false
		}
		let items = libraryGroup().items
		let itemIndex = itemIndex(forRow: row)
		guard 0 <= itemIndex, itemIndex < items.count else {
			return false
		}
		return true
	}
	
	func itemNonNil(atRow: Int) -> NSManagedObject {
		let itemIndex = itemIndex(forRow: atRow)
		return libraryGroup().items[itemIndex]
	}
	
	// MARK: Indices
	
	func itemIndex(forRow row: Int) -> Int {
		return row - prerowCount
	}
	
	// MARK: Rows
	
	func rowsForAllItems() -> [Int] {
		guard !isEmpty() else {
			return []
		}
		let indices = libraryGroup().items.indices
		return indices.map {
			prerowCount + $0
		}
	}
	
	func row(forItemIndex itemIndex: Int) -> Int {
		return prerowCount + itemIndex
	}
	
	// MARK: - Editing
	
	// MARK: Reorder
	
	mutating func moveItem(atRow: Int, toRow: Int) {
		let atIndex = itemIndex(forRow: atRow)
		let toIndex = itemIndex(forRow: toRow)
		
		var newItems = libraryGroup().items
		let itemBeingMoved = newItems.remove(at: atIndex)
		newItems.insert(itemBeingMoved, at: toIndex)
		groups[0].setItems(newItems)
	}
	
	// MARK: Sort
	
	func updatedAfterSorting(
		selectedRows: [Int],
		sortCommand: SortCommand
	) -> Self {
		var subjected: [Int] = selectedRows
		subjected.sort()
		if subjected.isEmpty {
			subjected = rowsForAllItems()
		}
		
		var twin = self
		let newItems = _itemsAfterSorting(
			itemsAtRowsInOrder: subjected,
			sortCommand: sortCommand)
		twin.groups[0].setItems(newItems)
		return twin
	}
	private func _itemsAfterSorting(
		itemsAtRowsInOrder rows: [Int],
		sortCommand: SortCommand
	) -> [NSManagedObject] {
		let oldItems = libraryGroup().items
		let subjectedIndices = rows.map { itemIndex(forRow: $0) }
		
		// Get just the items to sort, and get them sorted in a separate `Array`.
		let sortedItemsOnly: [NSManagedObject] = {
			let itemsToSort = subjectedIndices.map { itemIndex in
				oldItems[itemIndex]
			}
			return Self._sorted(
				itemsToSort,
				sortCommand: sortCommand)
		}()
		
		var result = oldItems
		result.replace(
			atIndices: subjectedIndices,
			withElements: sortedItemsOnly)
		return result
	}
	private static func _sorted(
		_ items: [NSManagedObject],
		sortCommand: SortCommand
	) -> [NSManagedObject] {
		switch sortCommand {
				
			case .random:
				return items.inAnyOtherOrder()
				
			case .reverse:
				return items.reversed()
				
				// Sort stably! Multiple items with the same name, disc number, or whatever property we’re sorting by should stay in the same order.
				// Use `sortedMaintainingOrderWhen` for convenience.
				
			case .folder_name:
				guard let folders = items as? [Collection] else {
					return items
				}
				return folders.sortedMaintainingOrderWhen {
					$0.title == $1.title
				} areInOrder: {
					let leftTitle = $0.title ?? ""
					let rightTitle = $1.title ?? ""
					return leftTitle.precedesAlphabeticallyFinderStyle(rightTitle)
				}
				
			case .album_released:
				guard let albums = items as? [Album] else {
					return items
				}
				return albums.sortedMaintainingOrderWhen {
					$0.releaseDateEstimate == $1.releaseDateEstimate
				} areInOrder: {
					$0.precedesByNewestFirst($1)
				}
				
			case .song_track:
				guard let songs = items as? [Song] else {
					return items
				}
				// Actually, return the songs grouped by disc number, and sorted by track number within each disc.
				let songsAndInfos = songs.map {
					(song: $0,
					 info: $0.songInfo())
				}
				let sorted = songsAndInfos.sortedMaintainingOrderWhen {
					let left = $0.info
					let right = $1.info
					return left?.discNumberOnDisk == right?.discNumberOnDisk
					&& left?.trackNumberOnDisk == right?.trackNumberOnDisk
				} areInOrder: {
					guard
						let left = $0.info,
						let right = $1.info
					else {
						return true
					}
					return left.precedesByTrackNumber(right)
				}
				return sorted.map { $0.song }
				
			case .song_added:
				guard let songs = items as? [Song] else {
					return items
				}
				let songsAndInfos = songs.map {
					(song: $0,
					 info: $0.songInfo())
				}
				let sorted = songsAndInfos.sortedMaintainingOrderWhen {
					left, right in
					return left.info?.dateAddedOnDisk == right.info?.dateAddedOnDisk
				} areInOrder: {
					guard
						let left = $0.info,
						let right = $1.info
					else {
						return true
					}
					return left.dateAddedOnDisk > right.dateAddedOnDisk
				}
				return sorted.map { $0.song }
				
		}
	}
}
