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
	var numberOfPrerowsPerSection: Int { get }
	
	var groups: ColumnOfLibraryItems { get set }
	
	func bigTitle() -> String
	func prerowIdentifiersInEachSection() -> [AnyHashable]
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
enum LibrarySectionIdentifier: Hashable {
	case groupWithNoContainer
	case groupWithContainer(NSManagedObjectID)
}
enum LibraryRowIdentifier: Hashable {
	case prerow(AnyHashable)
	case libraryItem(NSManagedObjectID)
}

extension LibraryViewModel {
	func isEmpty() -> Bool {
		return groups.allSatisfy { group in
			group.items.isEmpty
		}
	}
	
	func sectionStructures() -> [
		SectionStructure<LibrarySectionIdentifier, LibraryRowIdentifier>
	] {
		typealias LibrarySectionStructure = SectionStructure<
			LibrarySectionIdentifier,
			LibraryRowIdentifier
		>
		
		let groupSectionStructures: [LibrarySectionStructure] = groups.map { group in
			let sectionIdentifier: LibrarySectionIdentifier = {
				guard let containerID = group.container?.objectID else {
					return .groupWithNoContainer
				}
				return .groupWithContainer(containerID)
			}()
			
			let prerowIdentifiers = prerowIdentifiersInEachSection().map {
				LibraryRowIdentifier.prerow($0)
			}
			
			let itemRowIdentifiers = group.items.map { item in
				LibraryRowIdentifier.libraryItem(item.objectID)
			}
			
			let rowIdentifiers = prerowIdentifiers + itemRowIdentifiers
			
			return SectionStructure(
				identifier: sectionIdentifier,
				rowIdentifiers: rowIdentifiers)
		}
		
		return groupSectionStructures
	}
	
	// MARK: - Elements
	
	// WARNING: Never use `LibraryGroup.items[indexPath.row]`. That might return the wrong library item, because `IndexPath`s are offset by `numberOfPrerowsPerSection`.
	
	func libraryGroup() -> LibraryGroup {
		return groups[0]
	}
	
	func itemsInGroup(startingAt selectedIndexPath: IndexPath) -> [NSManagedObject] {
		let group = libraryGroup()
		let selectedItemIndex = itemIndex(forRow: selectedIndexPath.row)
		return Array(group.items[selectedItemIndex...])
	}
	
	func pointsToSomeItem(_ indexPath: IndexPath) -> Bool {
		let groupIndex = indexPath.section
		guard 0 <= groupIndex, groupIndex < groups.count else {
			return false
		}
		let items = groups[groupIndex].items
		let itemIndex = itemIndex(forRow: indexPath.row)
		guard 0 <= itemIndex, itemIndex < items.count else {
			return false
		}
		return true
	}
	
	func itemOptional(at indexPath: IndexPath) -> NSManagedObject? {
		guard pointsToSomeItem(indexPath) else {
			return nil
		}
		return itemNonNil(at: indexPath)
	}
	
	func itemNonNil(at indexPath: IndexPath) -> NSManagedObject {
		let group = libraryGroup()
		let itemIndex = itemIndex(forRow: indexPath.row)
		return group.items[itemIndex]
	}
	
	// MARK: Indices
	
	func itemIndex(forRow row: Int) -> Int {
		return row - numberOfPrerowsPerSection
	}
	
	// MARK: IndexPaths
	
	func indexPathsForAllItems() -> [IndexPath] {
		return groups.indices.flatMap { groupIndex in
			indexPaths(forGroupIndex: groupIndex)
		}
	}
	
	func row(forItemIndex itemIndex: Int) -> Int {
		return numberOfPrerowsPerSection + itemIndex
	}
	
	// Similar to UITableView.indexPathsForRows.
	func indexPaths(forGroupIndex groupIndex: Int) -> [IndexPath] {
		let indices = groups[groupIndex].items.indices
		return indices.map {
			IndexPath(
				row: numberOfPrerowsPerSection + $0,
				section: groupIndex)
		}
	}
	
	func indexPathFor(
		itemIndex: Int
	) -> IndexPath {
		return IndexPath(
			row: numberOfPrerowsPerSection + itemIndex,
			section: 0)
	}
	
	// MARK: - Editing
	
	// MARK: Reorder
	
	// WARNING: Leaves a group empty if you move all the items out of it. You must call `updatedWithFreshenedData` later to delete empty groups.
	mutating func moveItem(
		at sourceIndexPath: IndexPath,
		to destinationIndexPath: IndexPath
	) {
		let sourceGroupIndex = sourceIndexPath.section
		let sourceItemIndex = itemIndex(forRow: sourceIndexPath.row)
		
		var sourceItems = groups[sourceGroupIndex].items
		let item = sourceItems.remove(at: sourceItemIndex)
		groups[sourceGroupIndex].setItems(sourceItems)
		
		let destinationGroupIndex = destinationIndexPath.section
		let destinationItemIndex = itemIndex(forRow: destinationIndexPath.row)
		
		var destinationItems = groups[destinationGroupIndex].items
		destinationItems.insert(item, at: destinationItemIndex)
		groups[destinationGroupIndex].setItems(destinationItems)
	}
	
	// MARK: Sort
	
	func updatedAfterSorting(
		selectedRows: [Int],
		sortCommand: SortCommand
	) -> Self {
		var subjected: [Int] = selectedRows
		subjected.sort()
		if subjected.isEmpty {
			subjected = indexPathsForAllItems().map { $0.row }
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
		// Get all the items in the subjected group.
		let oldItems = libraryGroup().items
		
		// Get the indices of the items to sort.
		let subjectedIndices = rows.map {
			itemIndex(forRow: $0)
		}
		
		// Get just the items to sort, and get them sorted in a separate `Array`.
		let sortedItems: [NSManagedObject] = {
			let itemsToSort = subjectedIndices.map { itemIndex in
				oldItems[itemIndex]
			}
			return Self._sorted(
				itemsToSort,
				sortCommand: sortCommand)
		}()
		
		// Replace the subjected items with sorted items.
		let newItems: [NSManagedObject] = {
			var result = oldItems
			sortedItems.enumerated().forEach { (indexOfSortedItem, sortedItem) in
				let destinationIndex = subjectedIndices[indexOfSortedItem]
				result[destinationIndex] = sortedItem
			}
			return result
		}()
		return newItems
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
	
	// MARK: Float
	
	func updatedAfterFloating(
		selectedRowsInAnyOrder: [Int]
	) -> Self {
		var twin = self
		let newItems = itemsAfterFloating(selectedRowsInAnyOrder: selectedRowsInAnyOrder)
		twin.groups[0].setItems(newItems)
		return twin
	}
	private func itemsAfterFloating(
		selectedRowsInAnyOrder: [Int]
	) -> [NSManagedObject] {
		// We could use Swift Algorithms’s `MutableCollection.stablePartition` for this.
		
		let rows = selectedRowsInAnyOrder.sorted()
		let indicesOfSelectedItems = rows.map {
			itemIndex(forRow: $0)
		}
		let oldItems = libraryGroup().items
		let selectedItems = indicesOfSelectedItems.map {
			oldItems[$0]
		}
		
		var newItems = oldItems
		indicesOfSelectedItems.reversed().forEach {
			newItems.remove(at: $0)
		}
		selectedItems.reversed().forEach {
			newItems.insert($0, at: 0)
		}
		
		return newItems
	}
	
	// MARK: Sink
	
	func updatedAfterSinking(
		selectedRowsInAnyOrder: [Int]
	) -> Self {
		var twin = self
		let newItems = itemsAfterSinking(selectedRowsInAnyOrder: selectedRowsInAnyOrder)
		twin.groups[0].setItems(newItems)
		return twin
	}
	private func itemsAfterSinking(
		selectedRowsInAnyOrder: [Int]
	) -> [NSManagedObject] {
		let rows = selectedRowsInAnyOrder.sorted()
		let indicesOfSelectedItems = rows.map {
			itemIndex(forRow: $0)
		}
		let oldItems = libraryGroup().items
		let selectedItems = indicesOfSelectedItems.map {
			oldItems[$0]
		}
		
		var newItems = oldItems
		indicesOfSelectedItems.reversed().forEach {
			newItems.remove(at: $0)
		}
		selectedItems.forEach {
			newItems.append($0)
		}
		
		return newItems
	}
}
