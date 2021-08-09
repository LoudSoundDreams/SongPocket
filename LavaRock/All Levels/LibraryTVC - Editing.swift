//
//  LibraryTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension LibraryTVC {
	
	final override func setEditing(
		_ editing: Bool,
		animated: Bool
	) {
		if isEditing {
			context.tryToSave()
		}
		
		super.setEditing(
			editing,
			animated: animated)
		
		setBarButtons(animated: animated)
		
		tableView.performBatchUpdates(nil) // Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines). Otherwise, they'll stay the same size until they reload some other time, like after you edit them or scroll them offscreen and back onscreen.
		// During WWDC 2021, I did a lab in UIKit where the Apple engineer said that this is the best practice for doing this.
	}
	
	// MARK: - Allowing
	
	// You should only be allowed to sort contiguous items within the same SectionOfLibraryItems.
	final func allowsSort() -> Bool {
		guard !sectionOfLibraryItems.isEmpty() else {
			return false
		}
		
		if tableView.indexPathsForSelectedRowsNonNil.isEmpty {
			return true // Multisection: Only if we have exactly 1 SectionOfLibraryItems.
		} else {
			return tableView.indexPathsForSelectedRowsNonNil.isContiguousWithinSameSection()
		}
	}
	
	final func allowsMoveToTopOrBottom() -> Bool {
		return allowsFloat()
	}
	
	final func allowsFloat() -> Bool {
		guard !sectionOfLibraryItems.isEmpty() else {
			return false
		}
		
		if tableView.indexPathsForSelectedRowsNonNil.isEmpty {
			return false
		} else {
			return tableView.indexPathsForSelectedRowsNonNil.isWithinSameSection()
		}
	}
	
	final func allowsSink() -> Bool {
		return allowsFloat()
	}
	
	// MARK: - Moving to Top
	
	final func floatSelectedItemsToTopOfSection() {
		guard allowsFloat() else { return }
		
		// Make a new data source.
		
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil.sorted()
		let indexesOfSelectedItems = selectedIndexPaths.map { indexOfLibraryItem(for: $0) }
		let selectedItems = selectedIndexPaths.map { libraryItem(for: $0) }
		var newItems = sectionOfLibraryItems.items
		indexesOfSelectedItems.reversed().forEach { newItems.remove(at: $0) }
		
		selectedItems.reversed().forEach { newItems.insert($0, at: 0) }
		
		// Update the data source and table view.
		setItemsAndRefreshToMatch(newItems: newItems) {
			self.tableView.deselectAllRows(animated: true)
			self.didChangeRowsOrSelectedRows()
		}
	}
	
	// MARK: - Moving to Bottom
	
	final func sinkSelectedItemsToBottomOfSection() {
		guard allowsSink() else { return }
		
		// Make a new data source.
		
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil.sorted()
		let indexesOfSelectedItems = selectedIndexPaths.map { indexOfLibraryItem(for: $0) }
		let selectedItems = selectedIndexPaths.map { libraryItem(for: $0) }
		var newItems = sectionOfLibraryItems.items
		indexesOfSelectedItems.reversed().forEach { newItems.remove(at: $0) }
		
		selectedItems.forEach { newItems.append($0) }
		
		// Update the data source and table view.
		setItemsAndRefreshToMatch(newItems: newItems) {
			self.tableView.deselectAllRows(animated: true)
			self.didChangeRowsOrSelectedRows()
		}
	}
	
	// MARK: - Sorting
	
	final func sortOptionsMenu() -> UIMenu {
		let groupedChildren: [[UIAction]] = sortOptionsGrouped.map { sortOptionGroup in
			let groupOfChildren = sortOptionGroup.map { sortOption in
				UIAction(
					title: sortOption.localizedName()
				) { action in
					self.sortSelectedOrAllItems(sortOptionLocalizedName: action.title)
				}
			}
			return groupOfChildren
		}
		return UIMenu(
			presentsUpward: true,
			groupedChildren: groupedChildren)
	}
	
	private func sortSelectedOrAllItems(sortOptionLocalizedName: String) {
		guard allowsSort() else { return }
		
		// Get the indexes of the items to sort.
		let sourceIndexPaths: [IndexPath] = {
			if tableView.indexPathsForSelectedRowsNonNil.isEmpty {
				return indexPaths(forIndexOfSectionOfLibraryItems: 0)
			} else {
				return tableView.indexPathsForSelectedRowsNonNil.sorted()
			}
		}()
		let sourceIndexesOfItems = sourceIndexPaths.map { indexOfLibraryItem(for: $0) }
		
		// Get the items to sort.
		let itemsToSort = sourceIndexesOfItems.map { sectionOfLibraryItems.items[$0] }
		
		// Sort the items.
		let sortedItems = sorted(
			itemsToSort,
			sortOptionLocalizedName: sortOptionLocalizedName)
		
		// Make a new data source.
		var newItems = sectionOfLibraryItems.items
		sourceIndexesOfItems.reversed().forEach { newItems.remove(at: $0) }
		sortedItems.indices.forEach {
			let sortedItem = sortedItems[$0]
			let destinationIndex = sourceIndexesOfItems[$0]
			newItems.insert(sortedItem, at: destinationIndex)
		}
		
		// Update the data source and table view.
		setItemsAndRefreshToMatch(newItems: newItems) {
			self.tableView.deselectAllRows(animated: true)
			self.didChangeRowsOrSelectedRows()
		}
	}
	
	// Sorting should be stable! Multiple items with the same name, disc number, or whatever property we're sorting by should stay in the same order.
	private func sorted(
		_ items: [NSManagedObject],
		sortOptionLocalizedName: String?
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
	
}
