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
	
	var context: NSManagedObjectContext { get }
	var numberOfSectionsAboveLibraryItems: Int { get }
	var numberOfRowsAboveLibraryItemsInEachSection: Int { get }
	
	var groups: [GroupOfLibraryItems] { get set }
}

extension LibraryViewModel {
	
	func isEmpty() -> Bool {
		return groups.reduce(true) { werePreviousGroupsEmpty, group in
			werePreviousGroupsEmpty && group.items.isEmpty
		}
	}
	
	func sectionsAndNewItems() -> [
		(section: Int,
		 newItems: [NSManagedObject])
	] {
		let result = groups.indices.map { indexOfGroup in
			(
				numberOfSectionsAboveLibraryItems + indexOfGroup,
				groups[indexOfGroup].itemsFetched(
					entityName: Self.entityName,
					context: context)
			)
		}
		return result
	}
	
	func refreshContainers() {
		groups.forEach {
			$0.refreshContainer(context: context)
		}
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
	
	func item(for indexPath: IndexPath) -> NSManagedObject {
		let items = group(forSection: indexPath.section).items
		let indexOfItemInGroup = indexOfItemInGroup(forRow: indexPath.row)
		return items[indexOfItemInGroup]
	}
	
	// MARK: Indices
	
	func indexOfGroup(forSection section: Int) -> Int {
		return section - numberOfSectionsAboveLibraryItems
	}
	
	func indexOfItemInGroup(forRow row: Int) -> Int {
		return row - numberOfRowsAboveLibraryItemsInEachSection
	}
	
	// MARK: IndexPaths
	
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
				row: numberOfRowsAboveLibraryItemsInEachSection + $0,
				section: numberOfSectionsAboveLibraryItems + indexOfGroup)
		}
	}
	
	func indexPathFor(
		indexOfItemInGroup: Int,
		indexOfGroup: Int
	) -> IndexPath {
		return IndexPath(
			row: indexOfItemInGroup + numberOfRowsAboveLibraryItemsInEachSection,
			section: indexOfGroup + numberOfSectionsAboveLibraryItems)
	}
	
	// MARK: - UITableView
	
	// MARK: Numbers
	
	func numberOfSections() -> Int {
		return numberOfSectionsAboveLibraryItems + groups.count
	}
	
	func numberOfRows(inSection section: Int) -> Int {
		let group = group(forSection: section)
		if group.items.isEmpty {
			return 0 // Without numberOfRowsAboveLibraryItemsInEachSection
		} else {
			return numberOfRowsAboveLibraryItemsInEachSection + group.items.count
		}
	}
	
	// MARK: Editing
	
	// Identical to shouldBeginMultipleSelectionInteraction.
	// Similar to willSelectRow.
	func canEditRow(
		at indexPath: IndexPath
	) -> Bool {
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
			proposedDestinationIndexPath.row < numberOfRowsAboveLibraryItemsInEachSection
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
	func shouldBeginMultipleSelectionInteraction(
		at indexPath: IndexPath
	) -> Bool {
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
	func willSelectRow(
		at indexPath: IndexPath
	) -> IndexPath? {
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
	
	// MARK: Allowing
	
	// You should only be allowed to sort contiguous items within the same GroupOfLibraryItems.
	func allowsSort(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		guard !isEmpty() else {
			return false
		}
		
		if selectedIndexPaths.isEmpty {
			return groups.count == 1
		} else {
			return selectedIndexPaths.isWithinSameSection()
		}
	}
	
	func allowsFloat(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		guard !isEmpty() else {
			return false
		}
		
		if selectedIndexPaths.isEmpty {
			return false
		} else {
			return selectedIndexPaths.isWithinSameSection()
		}
	}
	
	func allowsSink(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		return allowsFloat(selectedIndexPaths: selectedIndexPaths)
	}
	
	// MARK: Reordering
	
	func itemsAfterMovingRow(
		at sourceIndexPath: IndexPath,
		to destinationIndexPath: IndexPath
	) -> (
		sourceSection: [NSManagedObject],
		destinationSection: [NSManagedObject]?
	) {
		let item = item(for: sourceIndexPath)
//		let indexOfSourceGroup = indexOfGroup(forSection: sourceIndexPath.section)
//		let indexOfDestinationGroup = indexOfGroup(forSection: destinationIndexPath.section)
		let sourceIndexOfItemInGroup = indexOfItemInGroup(forRow: sourceIndexPath.row)
		let destinationIndexOfItemInGroup = indexOfItemInGroup(forRow: destinationIndexPath.row)
		
//		groups[indexOfSourceGroup].items.remove(at: sourceIndexOfItemInGroup)
//		groups[indexOfDestinationGroup].items.insert(item, at: destinationIndexOfItemInGroup)
		
		let isMovingWithinSameSection = sourceIndexPath.section == destinationIndexPath.section
		
		let newItemsInSourceGroup: [NSManagedObject]
		let newItemsInDestinationGroup: [NSManagedObject]?
		if isMovingWithinSameSection {
			var newItems = group(forSection: sourceIndexPath.section).items
			newItems.remove(at: sourceIndexOfItemInGroup)
			newItems.insert(item, at: destinationIndexOfItemInGroup)
			
			newItemsInSourceGroup = newItems
			newItemsInDestinationGroup = nil
		} else {
			var newSourceItems = group(forSection: sourceIndexPath.section).items
			newSourceItems.remove(at: sourceIndexOfItemInGroup)
			
			var newDestinationItems = group(forSection: destinationIndexPath.section).items
			newDestinationItems.insert(item, at: destinationIndexOfItemInGroup)
			
			newItemsInSourceGroup = newSourceItems
			newItemsInDestinationGroup = newDestinationItems
		}
		
		return (
			newItemsInSourceGroup,
			newItemsInDestinationGroup
		)
	}
	
	// MARK: Sorting
	
	func itemsAfterSorting(
		rows: [Int],
		section: Int,
		sortOptionLocalizedName: String
	) -> [NSManagedObject] {
		let oldItems = group(forSection: section).items
		let rows = rows.sorted()
		let sourceIndicesOfItems = rows.map {
			indexOfItemInGroup(forRow: $0)
		}
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
		sortedItems.indices.forEach { indexOfSortedItem in
			let sortedItem = sortedItems[indexOfSortedItem]
			let destinationIndexOfItem = sourceIndicesOfItems[indexOfSortedItem]
			newItems.insert(sortedItem, at: destinationIndexOfItem)
		}
		return newItems
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
	
	func itemsAfterFloatingToTop(
		selectedRows: [Int],
		section: Int
	) -> [NSManagedObject] {
		let oldItems = group(forSection: section).items
		let selectedRows = selectedRows.sorted()
		let indicesOfSelectedItems = selectedRows.map {
			indexOfItemInGroup(forRow: $0)
		}
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
	
	// MARK: Moving to Bottom
	
	func itemsAfterSinkingToBottom(
		selectedRows: [Int],
		section: Int
	) -> [NSManagedObject] {
		let oldItems = group(forSection: section).items
		let selectedRows = selectedRows.sorted()
		let indicesOfSelectedItems = selectedRows.map {
			indexOfItemInGroup(forRow: $0)
		}
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
