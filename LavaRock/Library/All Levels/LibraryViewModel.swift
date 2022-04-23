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

typealias ColumnOfLibraryItems = [GroupOfLibraryItems]
extension ColumnOfLibraryItems {
	subscript(groupIndex: GroupIndex) -> GroupOfLibraryItems {
		get {
			self[groupIndex.__]
		}
		set {
			self[groupIndex.__] = newValue
		}
	}
}

protocol LibraryViewModel {
	static var entityName: String { get }
	
	var viewContainer: LibraryViewContainer { get }
	var context: NSManagedObjectContext { get }
	var numberOfPresections: SectionIndex { get }
	var numberOfPrerowsPerSection: RowIndex { get }
	
	var column: ColumnOfLibraryItems { get set }
	
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
		return column.allSatisfy { group in
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
		
		let groupSectionStructures: [LibrarySectionStructure] = column.map { group in
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
	
	// WARNING: Never use `GroupOfLibraryItems.items[indexPath.row]`. That might return the wrong library item, because `IndexPath`s are offset by `numberOfPrerowsPerSection`.
	
	func group(for section: SectionIndex) -> GroupOfLibraryItems {
		return column[groupIndex(for: section)]
	}
	
	func itemsInGroup(startingAt selectedIndexPath: IndexPath) -> [NSManagedObject] {
		let group = group(for: selectedIndexPath.sectionIndex)
		let selectedItemIndex = itemIndex(for: selectedIndexPath.rowIndex)
		return group.itemsFrom(selectedItemIndex)
	}
	
	func pointsToSomeItem(_ indexPath: IndexPath) -> Bool {
		let groupIndex = groupIndex(for: indexPath.sectionIndex)
		guard 0 <= groupIndex.__, groupIndex.__ < column.count else {
			return false
		}
		let items = column[groupIndex].items
		let itemIndex = itemIndex(for: indexPath.rowIndex)
		guard 0 <= itemIndex.__, itemIndex.__ < items.count else {
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
		let group = group(for: indexPath.sectionIndex)
		return group[itemIndex(for: indexPath.rowIndex)]
	}
	
	// MARK: Indices
	
	func groupIndex(for section: SectionIndex) -> GroupIndex {
		return GroupIndex(section.value - numberOfPresections.value)
	}
	
	func itemIndex(for row: RowIndex) -> ItemIndex {
		return ItemIndex(row.value - numberOfPrerowsPerSection.value)
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
		return column.indices.flatMap {
			indexPaths(for: GroupIndex($0))
		}
	}
	
	func section(for groupIndex: GroupIndex) -> SectionIndex {
		return SectionIndex(numberOfPresections.value + groupIndex.__)
	}
	
	func row(for itemIndex: ItemIndex) -> RowIndex {
		return RowIndex(numberOfPrerowsPerSection.value + itemIndex.__)
	}
	
	// Similar to UITableView.indexPathsForRows.
	func indexPaths(for groupIndex: GroupIndex) -> [IndexPath] {
		let indices = column[groupIndex].items.indices
		return indices.map {
			IndexPath(
				RowIndex(numberOfPrerowsPerSection.value + $0),
				in: SectionIndex(numberOfPresections.value + groupIndex.__))
		}
	}
	
	func indexPathFor(
		itemIndex: ItemIndex,
		groupIndex: GroupIndex
	) -> IndexPath {
		return IndexPath(
			RowIndex(numberOfPrerowsPerSection.value + itemIndex.__),
			in: SectionIndex(numberOfPresections.value + groupIndex.__))
	}
	
	// MARK: - UITableView
	
	func numberOfSections() -> Int {
		return numberOfPresections.value + column.count
	}
	
	func numberOfRows(for section: SectionIndex) -> Int {
		switch viewContainer {
		case .library:
			break
		case .container:
			break
		case .deleted:
			return 0 // Without `numberOfPrerowsPerSection`
		}
		let group = group(for: section)
		return numberOfPrerowsPerSection.value + group.items.count
	}
	
	// MARK: - Editing
	
	// WARNING: Leaves a group empty if you move all the items out of it. You must call `updatedWithFreshenedData` later to delete empty groups.
	mutating func moveItem(
		at sourceIndexPath: IndexPath,
		to destinationIndexPath: IndexPath
	) {
		let sourceGroupIndex = groupIndex(for: sourceIndexPath.sectionIndex)
		let sourceItemIndex = itemIndex(for: sourceIndexPath.rowIndex)
		
		var sourceItems = column[sourceGroupIndex].items
		let item = sourceItems.remove(at: sourceItemIndex.__)
		column[sourceGroupIndex].setItems(sourceItems)
		
		let destinationGroupIndex = groupIndex(for: destinationIndexPath.sectionIndex)
		let destinationItemIndex = itemIndex(for: destinationIndexPath.rowIndex)
		
		var destinationItems = column[destinationGroupIndex].items
		destinationItems.insert(item, at: destinationItemIndex.__)
		column[destinationGroupIndex].setItems(destinationItems)
	}
	
	func updatedAfterSorting(
		selectedIndexPaths: [IndexPath],
		sortOptionLocalizedName: String
	) -> Self {
		let indexPathsToSort = sortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
			selectedIndexPaths: selectedIndexPaths)
		
		let rowsBySection = indexPathsToSort.rowsBySection()
		
		var twin = self
		rowsBySection.forEach { (section, rows) in
			let newItems = itemsAfterSorting(
				itemsAtInOrder: rows,
				in: section,
				sortOptionLocalizedName: sortOptionLocalizedName)
			let groupIndex = groupIndex(for: section)
			twin.column[groupIndex].setItems(newItems)
		}
		return twin
	}
	
	private func itemsAfterSorting(
		itemsAtInOrder rows: [RowIndex],
		in section: SectionIndex,
		sortOptionLocalizedName: String
	) -> [NSManagedObject] {
		// Get all the items in the subjected group.
		let oldItems = group(for: section).items
		
		// Get the indices of the items to sort.
		let subjectedIndices = rows.map {
			itemIndex(for: $0)
		}
		
		// Get just the items to sort, and get them sorted in a separate `Array`.
		let sortedItems: [NSManagedObject] = {
			let itemsToSort = subjectedIndices.map { itemIndex in
				oldItems[itemIndex.__]
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
				result[destinationIndex.__] = sortedItem
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
		let rowsBySection = selectedIndexPaths.rowsBySection()
		
		var twin = self
		rowsBySection.forEach { (section, rows) in
			let newItems = itemsAfterFloatingToTop(
				itemsAtInAnyOrder: rows,
				in: section)
			let groupIndex = groupIndex(for: section)
			twin.column[groupIndex].setItems(newItems)
		}
		return twin
	}
	
	private func itemsAfterFloatingToTop(
		itemsAtInAnyOrder rowsInAnyOrder: [RowIndex],
		in section: SectionIndex
	) -> [NSManagedObject] {
		let rows = rowsInAnyOrder.sorted()
		let indicesOfSelectedItems = rows.map {
			itemIndex(for: $0)
		}
		let oldItems = group(for: section).items
		let selectedItems = indicesOfSelectedItems.map {
			oldItems[$0.__]
		}
		
		var newItems = oldItems
		indicesOfSelectedItems.reversed().forEach {
			newItems.remove(at: $0.__)
		}
		selectedItems.reversed().forEach {
			newItems.insert($0, at: 0)
		}
		
		return newItems
	}
	
	func updatedAfterSinkingToBottomsOfSections(
		selectedIndexPaths: [IndexPath]
	) -> Self {
		let rowsBySection = selectedIndexPaths.rowsBySection()
		
		var twin = self
		rowsBySection.forEach { (section, rows) in
			let newItems = itemsAfterSinkingToBottom(
				itemsAtInAnyOrder: rows,
				in: section)
			let groupIndex = groupIndex(for: section)
			twin.column[groupIndex].setItems(newItems)
		}
		return twin
	}
	
	private func itemsAfterSinkingToBottom(
		itemsAtInAnyOrder rowsInAnyOrder: [RowIndex],
		in section: SectionIndex
	) -> [NSManagedObject] {
		let rows = rowsInAnyOrder.sorted()
		let indicesOfSelectedItems = rows.map {
			itemIndex(for: $0)
		}
		let oldItems = group(for: section).items
		let selectedItems = indicesOfSelectedItems.map {
			oldItems[$0.__]
		}
		
		var newItems = oldItems
		indicesOfSelectedItems.reversed().forEach {
			newItems.remove(at: $0.__)
		}
		selectedItems.forEach {
			newItems.append($0)
		}
		
		return newItems
	}
}
