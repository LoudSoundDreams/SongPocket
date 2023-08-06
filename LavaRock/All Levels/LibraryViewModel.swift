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
	
	func bigTitle() -> String
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
			
			let prerowIdentifiers = prerowIdentifiers().map {
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
	
	// WARNING: Never use `LibraryGroup.items[indexPath.row]`. That might return the wrong library item, because `IndexPath`s are offset by `prerowCount`.
	
	func libraryGroup() -> LibraryGroup {
		return groups[0]
	}
	
	func items(startingAtRow: Int) -> [NSManagedObject] {
		let group = libraryGroup()
		let selectedItemIndex = itemIndex(forRow: startingAtRow)
		return Array(group.items[selectedItemIndex...])
	}
	
	func pointsToSomeItem(row: Int) -> Bool {
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
	
	// WARNING: Leaves a group empty if you move all the items out of it. You must call `updatedWithFreshenedData` later to delete empty groups.
	mutating func moveItem(
		atRow: Int,
		toRow: Int
	) {
		let sourceItemIndex = itemIndex(forRow: atRow)
		var sourceItems = libraryGroup().items
		let item = sourceItems.remove(at: sourceItemIndex)
		groups[0].setItems(sourceItems)
		
		let destinationItemIndex = itemIndex(forRow: toRow)
		var destinationItems = libraryGroup().items
		destinationItems.insert(item, at: destinationItemIndex)
		groups[0].setItems(destinationItems)
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
