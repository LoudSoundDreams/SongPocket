//
//  protocol LibraryViewModel.swift
//  protocol LibraryViewModel
//
//  Created by h on 2021-08-12.
//

import UIKit
import CoreData

protocol LibraryViewModel {
	static var entityName: String { get }
	static var numberOfSectionsAboveLibraryItems: Int { get }
	static var numberOfRowsAboveLibraryItemsInEachSection: Int { get }
	
	var context: NSManagedObjectContext { get }
	
	// weak
	var reflector: LibraryViewModelReflecting? { get }
	
	var groups: [GroupOfLibraryItems] { get set }
	var onlyGroup: GroupOfLibraryItems? { get }//set }
	
	func navigationItemTitleOptional() -> String?
}

extension LibraryViewModel {
	
	var onlyGroup: GroupOfLibraryItems? {
//		get {
			guard
				let firstGroup = groups.first,
				groups.count == 1
			else {
				return nil
			}
			return firstGroup
//		}
//		set {
//			guard groups.count == 1 else { return }
//			if let newValue = newValue {
//				groups[0] = newValue
//			} else {
//				groups.removeAll()
//			}
//		}
	}
	
	func isEmpty() -> Bool {
		return groups.allSatisfy { group in
			group.items.isEmpty
		}
	}
	
	func refreshContainersAndReflect() {
		groups.forEach { $0.refreshContainer(context: context) }
		reflector?.reflectContainerTitles()
	}
	
	func newItemsAndSections() -> [(
		newItems: [NSManagedObject],
		section: Int
	)] {
		let result: [([NSManagedObject], Int)] = groups.indices.map { indexOfGroup in
			let newItems = groups[indexOfGroup].itemsFetched(
				entityName: Self.entityName,
				context: context)
			let section = Self.numberOfSectionsAboveLibraryItems + indexOfGroup
			return (newItems, section)
		}
		return result
	}
	
	// MARK: - Elements
	
	// WARNING: Never use GroupOfLibraryItems.items[indexPath.row]. That might return the wrong library item, because IndexPaths are offset by numberOfRowsAboveLibraryItemsInEachSection.
	// That's a hack to let us use rows for album artwork and album info in SongsTVC, above the rows for library items.
	
	func group(forSection section: Int) -> GroupOfLibraryItems {
		let indexOfGroup = indexOfGroup(forSection: section)
		return groups[indexOfGroup]
	}
	
	func itemsInGroup(startingAt selectedIndexPath: IndexPath) -> [NSManagedObject] {
		let items = group(forSection: selectedIndexPath.section).items
		let selectedIndexOfItemInGroup = indexOfItemInGroup(forRow: selectedIndexPath.row)
		return Array(items[selectedIndexOfItemInGroup...])
	}
	
	func item(at indexPath: IndexPath) -> NSManagedObject {
		let items = group(forSection: indexPath.section).items
		let indexOfItemInGroup = indexOfItemInGroup(forRow: indexPath.row)
		return items[indexOfItemInGroup]
	}
	
	// MARK: Indices
	
	func indexOfGroup(forSection section: Int) -> Int {
		return section - Self.numberOfSectionsAboveLibraryItems
	}
	
	func indexOfItemInGroup(forRow row: Int) -> Int {
		return row - Self.numberOfRowsAboveLibraryItemsInEachSection
	}
	
	// MARK: IndexPaths
	
	func selectedOrAllIndexPathsInOnlyGroup(
		selectedIndexPaths: [IndexPath]
	) -> [IndexPath] {
		if selectedIndexPaths.isEmpty {
			if groups.count == 1 {
				return indexPaths(forIndexOfGroup: 0)
			} else {
				return []
			}
		} else {
			return selectedIndexPaths
		}
	}
	
	func indexPathsForAllItems() -> [IndexPath] {
		let result = groups.indices.flatMap { indexOfGroup in
			indexPaths(forIndexOfGroup: indexOfGroup)
		}
		return result
	}
	
	// Similar to UITableView.indexPathsForRows.
	func indexPaths(forIndexOfGroup indexOfGroup: Int) -> [IndexPath] {
		let indices = groups[indexOfGroup].items.indices
		return indices.map {
			IndexPath(
				row: Self.numberOfRowsAboveLibraryItemsInEachSection + $0,
				section: Self.numberOfSectionsAboveLibraryItems + indexOfGroup)
		}
	}
	
	func indexPathFor(
		indexOfItemInGroup: Int,
		indexOfGroup: Int
	) -> IndexPath {
		return IndexPath(
			row: indexOfItemInGroup + Self.numberOfRowsAboveLibraryItemsInEachSection,
			section: indexOfGroup + Self.numberOfSectionsAboveLibraryItems)
	}
	
	// MARK: - UITableView
	
	// MARK: Numbers
	
	func numberOfSections() -> Int {
		return Self.numberOfSectionsAboveLibraryItems + groups.count
	}
	
	func numberOfRows(forSection section: Int) -> Int {
		let group = group(forSection: section)
		if group.items.isEmpty {
			return 0 // Without numberOfRowsAboveLibraryItemsInEachSection
		} else {
			return Self.numberOfRowsAboveLibraryItemsInEachSection + group.items.count
		}
	}
	
	// MARK: Editing
	
	// Identical to shouldBeginMultipleSelectionInteraction.
	// Similar to willSelectRow.
	func canEditRow(at indexPath: IndexPath) -> Bool {
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
	
	// MARK: Reordering
	
	func targetIndexPathForMovingRow(
		at sourceIndexPath: IndexPath,
		to proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
		let proposedSection = proposedDestinationIndexPath.section
		if
			proposedSection == sourceIndexPath.section,
			proposedDestinationIndexPath.row < Self.numberOfRowsAboveLibraryItemsInEachSection
		{
			let indexOfGroup = indexOfGroup(forSection: proposedSection)
			return indexPathFor(
				indexOfItemInGroup: 0,
				indexOfGroup: indexOfGroup)
		} else {
			return proposedDestinationIndexPath
		}
	}
	
	// MARK: Selecting
	
	// Identical to canEditRow.
	// Similar to willSelectRow.
	func shouldBeginMultipleSelectionInteraction(at indexPath: IndexPath) -> Bool {
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
	
	// Similar to canEditRow and shouldBeginMultipleSelectionInteraction.
	// To disable selection for a row, it's simpler to set cell.isUserInteractionEnabled = false.
	// However, you can begin a multiple-selection interaction on a cell that does allow user interaction and shouldBeginMultipleSelectionInteractionAt, and swipe over a cell that doesn't allow user interaction, to select it too.
	// Therefore, if you support multiple-selection interactions, you must use this method to disable selection for certain rows.
	func willSelectRow(at indexPath: IndexPath) -> IndexPath? {
		let indexOfGroup = indexOfGroup(forSection: indexPath.section)
		guard 0 <= indexOfGroup, indexOfGroup < groups.count else {
			return nil
		}
		let items = groups[indexOfGroup].items
		
		let indexOfItemInGroup = indexOfItemInGroup(forRow: indexPath.row)
		guard 0 <= indexOfItemInGroup, indexOfItemInGroup < items.count else {
			return nil
		}
		
		return indexPath
	}
	
	// MARK: - Editing
	
	// MARK: Reordering
	
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
	
	// MARK: Sorting
	
	func itemsAndSectionAfterSorting(
		selectedIndexPaths: [IndexPath],
		sortOptionLocalizedName: String
	) -> (
		items: [NSManagedObject],
		section: Int
	)? {
		// Decide which rows to sort.
		let indexPathsToSort = selectedOrAllIndexPathsInOnlyGroup(
			selectedIndexPaths: selectedIndexPaths)
		
		guard let section = indexPathsToSort.first?.section else {
			return nil
		}
		
		// Get all the items in the group for the rows to sort.
		let oldItems = group(forSection: section).items
		
		// Get the indices of the items to sort.
		let rowsToSort = indexPathsToSort.map { $0.row }.sorted()
		let sourceIndicesOfItems = rowsToSort.map { row in
			indexOfItemInGroup(forRow: row)
		}
		
		// Sort the items.
		let itemsToSort = sourceIndicesOfItems.map {
			oldItems[$0]
		}
		let sortedItems = sorted(
			itemsToSort,
			sortOptionLocalizedName: sortOptionLocalizedName)
		
		// Make a new data source.
		var newItems = oldItems
		sourceIndicesOfItems.reversed().forEach {
			newItems.remove(at: $0)
		}
		sortedItems.indices.forEach {
			let sortedItem = sortedItems[$0]
			let destinationIndex = sourceIndicesOfItems[$0]
			newItems.insert(sortedItem, at: destinationIndex)
		}
		
		return (newItems, section)
	}
	
	// Sorting should be stable! Multiple items with the same name, disc number, or whatever property we're sorting by should stay in the same order.
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
	
	// MARK: Moving to Top
	
	func itemsAndSectionAfterFloatingSelectedItemsToTop(
		selectedIndexPaths: [IndexPath]
	) -> (
		items: [NSManagedObject],
		section: Int
	)? {
		guard let section = selectedIndexPaths.first?.section else {
			return nil
		}
		
		let selectedRows = selectedIndexPaths.map { $0.row }.sorted()
		let indicesOfSelectedItems = selectedRows.map {
			indexOfItemInGroup(forRow: $0)
		}
		let oldItems = group(forSection: section).items
		let selectedItems = indicesOfSelectedItems.map {
			oldItems[$0]
		}
		
		// Make a new data source.
		var newItems = oldItems
		indicesOfSelectedItems.reversed().forEach {
			newItems.remove(at: $0)
		}
		selectedItems.reversed().forEach {
			newItems.insert($0, at: 0)
		}
		
		return (newItems, section)
	}
	
	// MARK: Moving to Bottom
	
	func itemsAndSectionAfterSinkingSelectedItemsToBottom(
		selectedIndexPaths: [IndexPath]
	) -> (
		items: [NSManagedObject],
		section: Int
	)? {
		guard let section = selectedIndexPaths.first?.section else {
			return nil
		}
		
		let selectedRows = selectedIndexPaths.map { $0.row }.sorted()
		let indicesOfSelectedItems = selectedRows.map {
			indexOfItemInGroup(forRow: $0)
		}
		let oldItems = group(forSection: section).items
		let selectedItems = indicesOfSelectedItems.map {
			oldItems[$0]
		}
		
		// Make a new data source.
		var newItems = oldItems
		indicesOfSelectedItems.reversed().forEach {
			newItems.remove(at: $0)
		}
		selectedItems.forEach {
			newItems.append($0)
		}
		
		return (newItems, section)
	}
	
}
