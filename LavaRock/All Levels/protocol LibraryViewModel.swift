//
//  protocol LibraryViewModel.swift
//  LavaRock
//
//  Created by h on 2021-08-12.
//

import UIKit
import CoreData

enum LibraryViewContainer {
	case library
	case container(LibraryContainer)
	case deleted(LibraryContainer)
	
	func refreshed() -> Self {
		switch self {
		case .library:
			return .library
		case .container(let container):
			if container.wasDeleted() { // WARNING: You must check this, or the initializer will create groups with no items.
				return .deleted(container)
			} else {
				return .container(container)
			}
		case .deleted(let container):
			return .deleted(container)
		}
	}
}

protocol LibraryViewModel {
	static var entityName: String { get }
	
	var viewContainer: LibraryViewContainer { get }
	var context: NSManagedObjectContext { get }
	var numberOfPresections: Int { get }
	var numberOfPrerowsPerSection: Int { get }
	
	var groups: [GroupOfLibraryItems] { get set }
	
	func viewContainerIsSpecific() -> Bool
	func bigTitle() -> String
	func allowsSortOption(
		_ sortOption: LibraryTVC.SortOption,
		forItems items: [NSManagedObject]
	) -> Bool
	func updatedWithRefreshedData() -> Self
}

enum LibrarySectionIdentifier: Hashable {
//	case presection(Int)
	case groupWithNoContainer
	case groupWithContainer(NSManagedObjectID)
}

enum LibraryRowIdentifier: Hashable {
	case prerow(Int)
	case libraryItem(NSManagedObjectID)
}

extension LibraryViewModel {
	
	var onlyGroup: GroupOfLibraryItems? {
		guard
			let firstGroup = groups.first,
			groups.count == 1
		else {
			return nil
		}
		return firstGroup
	}
	
	func isEmpty() -> Bool {
		return groups.allSatisfy { group in
			group.items.isEmpty
		}
	}
	
	func newItemsAndSection(
		forIndexOfGroup indexOfGroup: Int
	) -> (
		newItems: [NSManagedObject],
		section: Int
	) {
		let newItems = groups[indexOfGroup].itemsFetched(
			entityName: Self.entityName,
			context: context)
		let section = numberOfPresections + indexOfGroup
		return (newItems, section)
	}
	
	func sectionStructures() -> [
		SectionStructure<LibrarySectionIdentifier, LibraryRowIdentifier>
	] {
		typealias LibrarySectionStructure = SectionStructure<
			LibrarySectionIdentifier,
			LibraryRowIdentifier
		>
		
//		let presectionIndices = Array(0 ..< numberOfPresections)
//		let presectionStructures: [LibrarySectionStructure] = presectionIndices.map { index in
//			let sectionIdentifier = LibrarySectionIdentifier.presection(index)
//
//			// TO DO: Actually support presections.
//
//			return SectionStructure(
//				identifier: sectionIdentifier,
//				rowIdentifiers: [])
//		}
		
		let groupSectionStructures: [LibrarySectionStructure] = groups.map { group in
			let sectionIdentifier: LibrarySectionIdentifier = {
				if let containerID = group.container?.objectID {
					return .groupWithContainer(containerID)
				} else {
					return .groupWithNoContainer
				}
			}()
			
			let prerowIndices = Array(0 ..< numberOfPrerowsPerSection)
			let prerowIdentifiers = prerowIndices.map { index in
				LibraryRowIdentifier.prerow(index) // RB2DO: Give different prerows different identifiers.
			}
			
			let itemRowIdentifiers = group.items.map { item in
				LibraryRowIdentifier.libraryItem(item.objectID)
			}
			
			let rowIdentifiers = prerowIdentifiers + itemRowIdentifiers
			
			return SectionStructure(
				identifier: sectionIdentifier,
				rowIdentifiers: rowIdentifiers)
		}
		
//		return presectionStructures + groupSectionStructures
		return groupSectionStructures
	}
	
	// MARK: - Elements
	
	// WARNING: Never use `GroupOfLibraryItems.items[indexPath.row]`. That might return the wrong library item, because `IndexPath`s are offset by `numberOfPrerowsPerSection`.
	
	func group(forSection section: Int) -> GroupOfLibraryItems {
		let indexOfGroup = indexOfGroup(forSection: section)
		return groups[indexOfGroup]
	}
	
	func itemsInGroup(startingAt selectedIndexPath: IndexPath) -> [NSManagedObject] {
		let items = group(forSection: selectedIndexPath.section).items
		let selectedIndexOfItemInGroup = indexOfItemInGroup(forRow: selectedIndexPath.row)
		return Array(items[selectedIndexOfItemInGroup...])
	}
	
	func pointsToSomeItem(_ indexPath: IndexPath) -> Bool {
		let indexOfGroup = indexOfGroup(forSection: indexPath.section)
		guard 0 <= indexOfGroup, indexOfGroup < groups.count else {
			return false
		}
		let items = groups[indexOfGroup].items
		let indexOfItemInGroup = indexOfItemInGroup(forRow: indexPath.row)
		guard 0 <= indexOfItemInGroup, indexOfItemInGroup < items.count else {
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
		let items = group(forSection: indexPath.section).items
		let indexOfItemInGroup = indexOfItemInGroup(forRow: indexPath.row)
		return items[indexOfItemInGroup]
	}
	
	// MARK: Indices
	
	func indexOfGroup(forSection section: Int) -> Int {
		return section - numberOfPresections
	}
	
	func indexOfItemInGroup(forRow row: Int) -> Int {
		return row - numberOfPrerowsPerSection
	}
	
	// MARK: IndexPaths
	
	func unsortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
		selectedIndexPaths: [IndexPath]
	) -> [IndexPath] {
		if selectedIndexPaths.isEmpty {
			if viewContainerIsSpecific() {
				return indexPathsForAllItems()
			} else {
				return []
			}
		} else {
			return selectedIndexPaths
		}
	}
	
	func sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
		selectedIndexPaths: [IndexPath]
	) -> [IndexPath] {
		if selectedIndexPaths.isEmpty {
			if viewContainerIsSpecific() {
				return indexPathsForAllItems()
			} else {
				return []
			}
		} else {
			return selectedIndexPaths.sorted()
		}
	}
	
	func indexPathsForAllItems() -> [IndexPath] {
		let result = groups.indices.flatMap { indexOfGroup in
			indexPaths(forIndexOfGroup: indexOfGroup)
		}
		return result
	}
	
	func isPresection(indexPath: IndexPath) -> Bool {
		return indexPath.section < numberOfPresections
	}
	
	func isPrerow(indexPath: IndexPath) -> Bool {
		return indexPath.row < numberOfPrerowsPerSection
	}
	
	func section(forIndexOfGroup indexOfGroup: Int) -> Int {
		return numberOfPresections + indexOfGroup
	}
	
	func row(forIndexOfItemInGroup indexOfItemInGroup: Int) -> Int {
		return numberOfPrerowsPerSection + indexOfItemInGroup
	}
	
	// Similar to UITableView.indexPathsForRows.
	func indexPaths(forIndexOfGroup indexOfGroup: Int) -> [IndexPath] {
		let indices = groups[indexOfGroup].items.indices
		return indices.map {
			IndexPath(
				row: numberOfPrerowsPerSection + $0,
				section: numberOfPresections + indexOfGroup)
		}
	}
	
	func indexPathFor(
		indexOfItemInGroup: Int,
		indexOfGroup: Int
	) -> IndexPath {
		return IndexPath(
			row: numberOfPrerowsPerSection + indexOfItemInGroup,
			section: numberOfPresections + indexOfGroup)
	}
	
	// MARK: - UITableView
	
	// MARK: Numbers
	
	func numberOfSections() -> Int {
		return numberOfPresections + groups.count
	}
	
	func numberOfRows(forSection section: Int) -> Int {
		let group = group(forSection: section)
		if group.items.isEmpty {
			return 0 // Without `numberOfPrerowsPerSection`
		} else {
			return numberOfPrerowsPerSection + group.items.count
		}
	}
	
	// MARK: - Editing
	
	// WARNING: Leaves a group empty if you move all the items out of it. You must call `updatedWithRefreshedData` later to delete empty groups.
	mutating func moveItem(
		at sourceIndexPath: IndexPath,
		to destinationIndexPath: IndexPath
	) {
		let sourceIndexOfGroup = indexOfGroup(forSection: sourceIndexPath.section)
		let sourceIndexOfItem = indexOfItemInGroup(forRow: sourceIndexPath.row)
		
		var sourceItems = groups[sourceIndexOfGroup].items
		let item = sourceItems.remove(at: sourceIndexOfItem)
		groups[sourceIndexOfGroup].setItems(sourceItems)
		
		let destinationIndexOfGroup = indexOfGroup(forSection: destinationIndexPath.section)
		let destinationIndexOfItem = indexOfItemInGroup(forRow: destinationIndexPath.row)
		
		var destinationItems = groups[destinationIndexOfGroup].items
		destinationItems.insert(item, at: destinationIndexOfItem)
		groups[destinationIndexOfGroup].setItems(destinationItems)
	}
	
	func updatedAfterSorting(
		selectedIndexPaths: [IndexPath],
		sortOptionLocalizedName: String
	) -> Self {
		let indexPathsToSort = sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: selectedIndexPaths)
		
		let rowsBySection = indexPathsToSort.makeDictionaryOfRowsBySection()
		
		var twin = self
		rowsBySection.forEach { (section, rows) in
			let newItems = itemsAfterSorting(
				itemsAtRowsInOrder: rows,
				inSection: section,
				sortOptionLocalizedName: sortOptionLocalizedName)
			let indexOfGroup = indexOfGroup(forSection: section)
			twin.groups[indexOfGroup].setItems(newItems)
		}
		return twin
	}
	
	private func itemsAfterSorting(
		itemsAtRowsInOrder rows: [Int],
		inSection section: Int,
		sortOptionLocalizedName: String
	) -> [NSManagedObject] {
		// Get all the items in the group for the rows to sort.
		let oldItems = group(forSection: section).items
		
		// Get the indices of the items to sort.
		let sourceIndicesOfItems = rows.map { row in
			indexOfItemInGroup(forRow: row)
		}
		
		// Sort the items.
		let itemsToSort = sourceIndicesOfItems.map {
			oldItems[$0]
		}
		let sortedItems = sorted(
			itemsToSort,
			sortOptionLocalizedName: sortOptionLocalizedName)
		
		var newItems = oldItems
		sourceIndicesOfItems.reversed().forEach {
			newItems.remove(at: $0)
		}
		sortedItems.indices.forEach {
			let sortedItem = sortedItems[$0]
			let destinationIndex = sourceIndicesOfItems[$0]
			newItems.insert(sortedItem, at: destinationIndex)
		}
		
		return newItems
	}
	
	// Sort stably! Multiple items with the same name, disc number, or whatever property we're sorting by should stay in the same order.
	private func sorted(
		_ items: [NSManagedObject],
		sortOptionLocalizedName: String
	) -> [NSManagedObject] {
		switch sortOptionLocalizedName {
			
		case LocalizedString.title:
			guard let collections = items as? [Collection] else {
				return items
			}
			return collections.sorted {
				let collectionTitle0 = $0.title ?? ""
				let collectionTitle1 = $1.title ?? ""
				return collectionTitle0.precedesAlphabeticallyFinderStyle(collectionTitle1)
			}
			
			// Albums only
		case LocalizedString.newestFirst:
			guard let albums = items as? [Album] else {
				return items
			}
			return albums.sortedMaintainingOrderWhen {
				$0.releaseDateEstimate == $1.releaseDateEstimate
			} areInOrder: {
				$0.precedesForSortOptionNewestFirst($1)
			}
		case LocalizedString.oldestFirst:
			guard let albums = items as? [Album] else {
				return items
			}
			return albums.sortedMaintainingOrderWhen {
				$0.releaseDateEstimate == $1.releaseDateEstimate
			} areInOrder: {
				$0.precedesForSortOptionOldestFirst($1)
			}
			
			// Songs only
		case LocalizedString.trackNumber:
			guard let songs = items as? [Song] else {
				return items
			}
			// Actually, return the songs grouped by disc number, and sorted by track number within each disc.
			let songsAndMediaItems = songs.map { ($0, $0.mpMediaItem()) }
			let sorted = songsAndMediaItems.sortedMaintainingOrderWhen {
				let leftMediaItem = $0.1
				let rightMediaItem = $1.1
				return leftMediaItem?.discNumber == rightMediaItem?.discNumber
				&& leftMediaItem?.albumTrackNumber == rightMediaItem?.albumTrackNumber
			} areInOrder: {
				guard
					let leftMediaItem = $0.1,
					let rightMediaItem = $1.1
				else {
					return true
				}
				return leftMediaItem.precedesForSortOptionTrackNumber(rightMediaItem)
			}
			return sorted.map { $0.0 }
			
		case LocalizedString.reverse:
			return items.reversed()
			
		default:
			return items
			
		}
	}
	
	func updatedAfterFloatingToTopsOfSections(
		selectedIndexPaths: [IndexPath]
	) -> Self {
		let rowsBySection = selectedIndexPaths.makeDictionaryOfRowsBySection()
		
		var twin = self
		rowsBySection.forEach { (section, rows) in
			let newItems = itemsAfterFloatingToTop(
				itemsAtRowsInAnyOrder: rows,
				inSection: section)
			let indexOfGroup = indexOfGroup(forSection: section)
			twin.groups[indexOfGroup].setItems(newItems)
		}
		return twin
	}
	
	private func itemsAfterFloatingToTop(
		itemsAtRowsInAnyOrder rowsInAnyOrder: [Int],
		inSection section: Int
	) -> [NSManagedObject] {
		let rows = rowsInAnyOrder.sorted()
		let indicesOfSelectedItems = rows.map {
			indexOfItemInGroup(forRow: $0)
		}
		let oldItems = group(forSection: section).items
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
	
	func updatedAfterSinkingToBottomsOfSections(
		selectedIndexPaths: [IndexPath]
	) -> Self {
		let rowsBySection = selectedIndexPaths.makeDictionaryOfRowsBySection()
		
		var twin = self
		rowsBySection.forEach { (section, rows) in
			let newItems = itemsAfterSinkingToBottom(
				itemsAtRowsInAnyOrder: rows,
				inSection: section)
			let indexOfGroup = indexOfGroup(forSection: section)
			twin.groups[indexOfGroup].setItems(newItems)
		}
		return twin
	}
	
	private func itemsAfterSinkingToBottom(
		itemsAtRowsInAnyOrder rowsInAnyOrder: [Int],
		inSection section: Int
	) -> [NSManagedObject] {
		let rows = rowsInAnyOrder.sorted()
		let indicesOfSelectedItems = rows.map {
			indexOfItemInGroup(forRow: $0)
		}
		let oldItems = group(forSection: section).items
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
