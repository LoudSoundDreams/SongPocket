//
//  LibraryViewModel.swift
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
	
	func freshened() -> Self {
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

typealias ColumnOfLibraryItems = [LibraryGroup]

protocol LibraryViewModel {
	static var entityName: String { get }
	
	var viewContainer: LibraryViewContainer { get }
	var context: NSManagedObjectContext { get }
	var numberOfPresections: Int { get }
	var numberOfPrerowsPerSection: Int { get }
	
	var groups: ColumnOfLibraryItems { get set }
	
	func viewContainerIsSpecific() -> Bool
	func bigTitle() -> String
	func prerowIdentifiersInEachSection() -> [AnyHashable]
	func allowsSortOption(
		_ sortOption: LibrarySortOption,
		forItems items: [NSManagedObject]
	) -> Bool
	func updatedWithFreshenedData() -> Self
}

enum LibrarySectionIdentifier: Hashable {
//	case presection(Int)
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
		
//		let presectionIndices = Array(0 ..< numberOfPresections)
//		let presectionStructures: [LibrarySectionStructure] = presectionIndices.map { index in
//			let sectionIdentifier = LibrarySectionIdentifier.presection(index)
//
//
//			return SectionStructure(
//				identifier: sectionIdentifier,
//				rowIdentifiers: [])
//		}
		
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
		
//		return presectionStructures + groupSectionStructures
		return groupSectionStructures
	}
	
	// MARK: - Elements
	
	// WARNING: Never use `LibraryGroup.items[indexPath.row]`. That might return the wrong library item, because `IndexPath`s are offset by `numberOfPrerowsPerSection`.
	
	func group(forSection section: Int) -> LibraryGroup {
		return groups[groupIndex(forSection: section)]
	}
	
	func itemsInGroup(startingAt selectedIndexPath: IndexPath) -> [NSManagedObject] {
		let group = group(forSection: selectedIndexPath.section)
		let selectedItemIndex = itemIndex(forRow: selectedIndexPath.row)
		return Array(group.items[selectedItemIndex...])
	}
	
	func pointsToSomeItem(_ indexPath: IndexPath) -> Bool {
		let groupIndex = groupIndex(forSection: indexPath.section)
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
		let group = group(forSection: indexPath.section)
		let itemIndex = itemIndex(forRow: indexPath.row)
		return group.items[itemIndex]
	}
	
	// MARK: Indices
	
	func groupIndex(forSection section: Int) -> Int {
		return section - numberOfPresections
	}
	
	func itemIndex(forRow row: Int) -> Int {
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
		return groups.indices.flatMap { groupIndex in
			indexPaths(forGroupIndex: groupIndex)
		}
	}
	
	func section(forGroupIndex groupIndex: Int) -> Int {
		return numberOfPresections + groupIndex
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
				section: numberOfPresections + groupIndex)
		}
	}
	
	func indexPathFor(
		itemIndex: Int,
		groupIndex: Int
	) -> IndexPath {
		return IndexPath(
			row: numberOfPrerowsPerSection + itemIndex,
			section: numberOfPresections + groupIndex)
	}
	
	// MARK: - UITableView
	
	func numberOfRows(forSection section: Int) -> Int {
		switch viewContainer {
		case
				.library,
				.container:
			break
		case .deleted:
			return 0 // Without `numberOfPrerowsPerSection`
		}
		let group = group(forSection: section)
		return numberOfPrerowsPerSection + group.items.count
	}
	
	// MARK: - Editing
	
	// WARNING: Leaves a group empty if you move all the items out of it. You must call `updatedWithFreshenedData` later to delete empty groups.
	mutating func moveItem(
		at sourceIndexPath: IndexPath,
		to destinationIndexPath: IndexPath
	) {
		let sourceGroupIndex = groupIndex(forSection: sourceIndexPath.section)
		let sourceItemIndex = itemIndex(forRow: sourceIndexPath.row)
		
		var sourceItems = groups[sourceGroupIndex].items
		let item = sourceItems.remove(at: sourceItemIndex)
		groups[sourceGroupIndex].setItems(sourceItems)
		
		let destinationGroupIndex = groupIndex(forSection: destinationIndexPath.section)
		let destinationItemIndex = itemIndex(forRow: destinationIndexPath.row)
		
		var destinationItems = groups[destinationGroupIndex].items
		destinationItems.insert(item, at: destinationItemIndex)
		groups[destinationGroupIndex].setItems(destinationItems)
	}
	
	func updatedAfterSorting(
		selectedIndexPaths: [IndexPath],
		sortOptionLocalizedName: String
	) -> Self {
		let indexPathsToSort = sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: selectedIndexPaths)
		
		let rowsBySection = indexPathsToSort.unsortedRowsBySection()
		
		var twin = self
		rowsBySection.forEach { (section, rows) in
			let newItems = itemsAfterSorting(
				itemsAtRowsInOrder: rows,
				inSection: section,
				sortOptionLocalizedName: sortOptionLocalizedName)
			let groupIndex = groupIndex(forSection: section)
			twin.groups[groupIndex].setItems(newItems)
		}
		return twin
	}
	
	private func itemsAfterSorting(
		itemsAtRowsInOrder rows: [Int],
		inSection section: Int,
		sortOptionLocalizedName: String
	) -> [NSManagedObject] {
		// Get all the items in the subjected group.
		let oldItems = group(forSection: section).items
		
		// Get the indices of the items to sort.
		let subjectedIndices = rows.map {
			itemIndex(forRow: $0)
		}
		
		// Get just the items to sort, and get them sorted in a separate `Array`.
		let sortedItems: [NSManagedObject] = {
			let itemsToSort = subjectedIndices.map { itemIndex in
				oldItems[itemIndex]
			}
			return Self.sorted(
				itemsToSort,
				sortOptionLocalizedName: sortOptionLocalizedName)
		}()
		
		// Create the new `Array` of items for the subjected group.
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
	
	// Sort stably! Multiple items with the same name, disc number, or whatever property we’re sorting by should stay in the same order.
	private static func sorted(
		_ items: [NSManagedObject],
		sortOptionLocalizedName: String
	) -> [NSManagedObject] {
		guard let sortOption = LibrarySortOption(localizedName: sortOptionLocalizedName) else {
			return items
		}
		switch sortOption {
			
		case .title:
			guard let collections = items as? [Collection] else {
				return items
			}
			return collections.sorted {
				let collectionTitle0 = $0.title ?? ""
				let collectionTitle1 = $1.title ?? ""
				return collectionTitle0.precedesAlphabeticallyFinderStyle(collectionTitle1)
			}
			
		case .newestFirst:
			guard let albums = items as? [Album] else {
				return items
			}
			return albums.sortedMaintainingOrderWhen {
				$0.releaseDateEstimate == $1.releaseDateEstimate
			} areInOrder: {
				$0.precedesForSortOptionNewestFirst($1)
			}
		case .oldestFirst:
			guard let albums = items as? [Album] else {
				return items
			}
			return albums.sortedMaintainingOrderWhen {
				$0.releaseDateEstimate == $1.releaseDateEstimate
			} areInOrder: {
				$0.precedesForSortOptionOldestFirst($1)
			}
			
		case .trackNumber:
			guard let songs = items as? [Song] else {
				return items
			}
			// Actually, return the songs grouped by disc number, and sorted by track number within each disc.
			let songsAndMetadata = songs.map {
				(song: $0,
				 metadatum: $0.metadatum())
			}
			let sorted = songsAndMetadata.sortedMaintainingOrderWhen {
				let leftMetadatum = $0.metadatum
				let rightMetadatum = $1.metadatum
				return leftMetadatum?.discNumberOnDisk == rightMetadatum?.discNumberOnDisk
				&& leftMetadatum?.trackNumberOnDisk == rightMetadatum?.trackNumberOnDisk
			} areInOrder: {
				guard
					let leftMetadatum = $0.metadatum,
					let rightMetadatum = $1.metadatum
				else {
					return true
				}
				return leftMetadatum.precedesForSortOptionTrackNumber(rightMetadatum)
			}
			return sorted.map { $0.song }
			
		case .shuffle:
			return items.inAnyOtherOrder()
			
		case .reverse:
			return items.reversed()
			
		}
	}
	
	func updatedAfterFloatingToTopsOfSections(
		selectedIndexPaths: [IndexPath]
	) -> Self {
		let rowsBySection = selectedIndexPaths.unsortedRowsBySection()
		
		var twin = self
		rowsBySection.forEach { (section, rows) in
			let newItems = itemsAfterFloatingToTop(
				itemsAtRowsInAnyOrder: rows,
				inSection: section)
			let groupIndex = groupIndex(forSection: section)
			twin.groups[groupIndex].setItems(newItems)
		}
		return twin
	}
	
	private func itemsAfterFloatingToTop(
		itemsAtRowsInAnyOrder rowsInAnyOrder: [Int],
		inSection section: Int
	) -> [NSManagedObject] {
		// We could use Swift Algorithms's `MutableCollection.stablePartition` for this.
		
		let rows = rowsInAnyOrder.sorted()
		let indicesOfSelectedItems = rows.map {
			itemIndex(forRow: $0)
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
		let rowsBySection = selectedIndexPaths.unsortedRowsBySection()
		
		var twin = self
		rowsBySection.forEach { (section, rows) in
			let newItems = itemsAfterSinkingToBottom(
				itemsAtRowsInAnyOrder: rows,
				inSection: section)
			let groupIndex = groupIndex(forSection: section)
			twin.groups[groupIndex].setItems(newItems)
		}
		return twin
	}
	
	private func itemsAfterSinkingToBottom(
		itemsAtRowsInAnyOrder rowsInAnyOrder: [Int],
		inSection section: Int
	) -> [NSManagedObject] {
		let rows = rowsInAnyOrder.sorted()
		let indicesOfSelectedItems = rows.map {
			itemIndex(forRow: $0)
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
