//
//  Editing - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension LibraryTVC {
	
	final override func setEditing(_ editing: Bool, animated: Bool) {
		if isEditing {
			managedObjectContext.tryToSave()
		}
		
		super.setEditing(editing, animated: animated)
		
		refreshAndSetBarButtons(animated: animated)
		
		// Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines).
		// Otherwise, they'll stay the same size until they reload some other time, like after you edit them or they leave memory.
		tableView.performBatchUpdates(nil, completion: nil)
	}
	
	// Note: We handle rearranging in UITableViewDataSource and UITableViewDelegate methods.
	
	// MARK: - Moving to Top
	
	@objc final func moveSelectedItemsToTop() {
		moveItemsUp(
			from: tableView.indexPathsForSelectedRows,
			to: indexPathFor(
				indexOfLibraryItem: 0,
				indexOfSectionOfLibraryItem: 0)
		)
	}
	
	// Note: Every IndexPath in selectedIndexPaths must be in the same section as firstIndexPath, and at or down below firstIndexPath.
	private func moveItemsUp(from selectedIndexPaths: [IndexPath]?, to firstIndexPath: IndexPath) {
		guard
			tableView.shouldAllowMovingSelectedRowsToTopOfSection(),
			let selectedIndexPaths = selectedIndexPaths
		else { return }
		// Make sure every IndexPaths in selectedIndexPaths is in the same section as firstIndexPath, and at or down below firstIndexPath.
		for selectedIndexPath in selectedIndexPaths {
			if selectedIndexPath.section != firstIndexPath.section || selectedIndexPath.row < firstIndexPath.row {
				return
			}
		}
		
		let pairsToMove = tuplesOfIndexPathsAndItems(
			selectedIndexPaths.sorted(),
			sectionItems: sectionOfLibraryItems.items,
			rowForFirstItem: numberOfRowsAboveLibraryItems)
		
		let targetSection = firstIndexPath.section
		var targetRow = firstIndexPath.row
		var selectedAndTargetIndexPaths = [(IndexPath, IndexPath)]()
		for (selectedIndexPath, matchingItem) in pairsToMove {
			let targetIndexPath = IndexPath(row: targetRow, section: targetSection)
			selectedAndTargetIndexPaths.append(
				(selectedIndexPath, targetIndexPath))
			
			let sourceIndexOfItem = indexOfLibraryItem(for: selectedIndexPath)
			let destinationIndexOfItem = indexOfLibraryItem(for: targetIndexPath)
			sectionOfLibraryItems.items.remove(at: sourceIndexOfItem)
			sectionOfLibraryItems.items.insert(matchingItem, at: destinationIndexOfItem)
			
			targetRow += 1
		}
		
		tableView.moveRows(
			atIndexPathsToIndexPathsIn: selectedAndTargetIndexPaths,
			completion: { [self] in
				for (_, targetIndexPath) in selectedAndTargetIndexPaths {
					tableView.deselectRow(at: targetIndexPath, animated: true)
				}
				refreshBarButtons()
			}
		)
	}
	
	// MARK: - Moving to Bottom
	
	@objc final func sinkSelectedItemsToBottom() {
		guard
			tableView.shouldAllowMovingSelectedRowsToBottomOfSection(),
			let selectedIndexPaths = tableView.indexPathsForSelectedRows
		else { return }
		
		let sortedSelectedIndexPaths = selectedIndexPaths.sorted()
		let pairsToMove = tuplesOfIndexPathsAndItems(
			sortedSelectedIndexPaths,
			sectionItems: sectionOfLibraryItems.items,
			rowForFirstItem: numberOfRowsAboveLibraryItems)
		guard let targetSection = sortedSelectedIndexPaths.last?.section else { return }
		
		var targetRow = tableView.numberOfRows(inSection: targetSection) - 1
		var selectedAndTargetIndexPaths = [(IndexPath, IndexPath)]()
		for (selectedIndexPath, matchingItem) in pairsToMove.reversed() {
			let targetIndexPath = IndexPath(row: targetRow, section: targetSection)
			selectedAndTargetIndexPaths.append(
				(selectedIndexPath, targetIndexPath))
			
			let sourceIndexOfItem = indexOfLibraryItem(for: selectedIndexPath)
			let destinationIndexOfItem = indexOfLibraryItem(for: targetIndexPath)
			sectionOfLibraryItems.items.remove(at: sourceIndexOfItem)
			sectionOfLibraryItems.items.insert(matchingItem, at: destinationIndexOfItem)
			
			targetRow -= 1
		}
		
		tableView.moveRows(
			atIndexPathsToIndexPathsIn: selectedAndTargetIndexPaths,
			completion: { [self] in
				for (_, targetIndexPath) in selectedAndTargetIndexPaths {
					tableView.deselectRow(at: targetIndexPath, animated: true)
				}
				refreshBarButtons()
			}
		)
	}
	
	// MARK: - Sorting
	
	// Unfortunately, we can't save UIAlertActions as constant properties of LibraryTVC. They're view controllers.
	@objc final func showSortOptionsActionSheet() {
		let actionSheet = UIAlertController(
			title: LocalizedString.sortBy,
			message: nil,
			preferredStyle: .actionSheet)
		for sortOption in sortOptions {
			actionSheet.addAction(
				UIAlertAction(
					title: sortOption.localizedName(),
					style: .default,
					handler: sortSelectedOrAllItems(_:)))
		}
		actionSheet.addAction(
			UIAlertAction(
				title: LocalizedString.cancel,
				style: .cancel,
				handler: nil)
		)
		actionSheet.popoverPresentationController?.barButtonItem = sortButton
		
		present(actionSheet, animated: true, completion: nil)
	}
	
	private func sortSelectedOrAllItems(_ sender: UIAlertAction) {
		guard let sortOptionLocalizedName = sender.title else { return }
		sortSelectedOrAllItems(sortOptionLocalizedName: sortOptionLocalizedName)
	}
	
	final func sortActionHandler(_ sender: UIAction) {
		sortSelectedOrAllItems(sortOptionLocalizedName: sender.title)
	}
	
	private func sortSelectedOrAllItems(sortOptionLocalizedName: String) {
		guard tableView.shouldAllowSorting() else { return }
		
		// Get the rows to sort.
		let indexPathsToSort = tableView.selectedOrEnumeratedIndexPathsIn(
			section: 0,
			firstRow: numberOfRowsAboveLibraryItems)
		guard !indexPathsToSort.isEmpty else { return }
		
		// Get the items to sort, too.
		let selectedIndexPathsAndItems = tuplesOfIndexPathsAndItems(
			indexPathsToSort,
			sectionItems: sectionOfLibraryItems.items,
			rowForFirstItem: numberOfRowsAboveLibraryItems)
		
		// Sort the rows and items together.
		let sortedIndexPathsAndItems =
			sorted(
				selectedIndexPathsAndItems,
				sortOptionLocalizedName: sortOptionLocalizedName)
		
		// Remove the selected items from the data source.
		for indexPath in indexPathsToSort.reversed() {
			let indexOfItemToRemove = indexOfLibraryItem(for: indexPath)
			sectionOfLibraryItems.items.remove(at: indexOfItemToRemove)
		}
		
		// Put the sorted items into the data source.
		let indexToInsertItemAt = indexPathsToSort.first!.row - numberOfRowsAboveLibraryItems
		for (_, item) in sortedIndexPathsAndItems.reversed() {
			sectionOfLibraryItems.items.insert(
				item,
				at: indexToInsertItemAt)
		}
		
		// Update the table view.
		var sortedIndexPaths = [IndexPath]()
		for indexPathAndItem in sortedIndexPathsAndItems {
			sortedIndexPaths.append(indexPathAndItem.0)
		}
		moveRowsUpToEarliestRow( // You could use tableView.reloadRows, but none of those animations show the individual rows moving to their destinations.
			from: sortedIndexPaths,
			completion: {
//				self.tableView.deselectRows(at: indexPathsToSort, animated: true) // This leaves the (editing mode) toolbar buttons out of date.
			})
		
		// Update the rest of the UI.
		tableView.deselectAllRows(animated: true) // TO DO: Wait until we finish moving the rows to do this, to match what happens after we tap "move to top" or "move to bottom".
		refreshBarButtons()
	}
	
	// Sorting should be stable! Multiple items with the same name, disc number, or whatever property we're sorting by should stay in the same order.
	private func sorted(
		_ indexPathsAndItemsImmutable: [(IndexPath, NSManagedObject)],
		sortOptionLocalizedName: String?
	) -> [(IndexPath, NSManagedObject)] {
		switch sortOptionLocalizedName {
		
		case LocalizedString.title:
			var indexPathsAndItemsCopy = indexPathsAndItemsImmutable
			if self is CollectionsTVC {
				indexPathsAndItemsCopy.sort {
					// Don't sort by <. It puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
					let collectionTitle0 = ($0.1 as? Collection)?.title ?? ""
					let collectionTitle1 = ($1.1 as? Collection)?.title ?? ""
					let comparisonResult = collectionTitle0.localizedStandardCompare(collectionTitle1) // The comparison method that the Finder uses
					return comparisonResult == .orderedAscending
				}
			}
			// If we're sorting Albums or Songs, use the methods in `extension Album` or `extension Song` to fetch their titles (or placeholders).
			return indexPathsAndItemsCopy
		
		// Albums only
		case LocalizedString.newestFirst:
			let commonDate = Date()
			return indexPathsAndItemsImmutable.sorted {
				($0.1 as? Album)?.releaseDateEstimate ?? commonDate >
					($1.1 as? Album)?.releaseDateEstimate ?? commonDate
			}
		case LocalizedString.oldestFirst:
			let commonDate = Date()
			return indexPathsAndItemsImmutable.sorted {
				($0.1 as? Album)?.releaseDateEstimate ?? commonDate <
					($1.1 as? Album)?.releaseDateEstimate ?? commonDate
			}
		
		// Songs only
		case LocalizedString.trackNumber:
			// Actually, return the items grouped by disc number, and sorted by track number within each disc.
			let sortedByTrackNumber = indexPathsAndItemsImmutable.sorted {
				($0.1 as? Song)?.mpMediaItem()?.albumTrackNumber ?? 0 <
					($1.1 as? Song)?.mpMediaItem()?.albumTrackNumber ?? 0
			}
			let sortedByTrackNumberWithZeroAtEnd = sortedByTrackNumber.sorted {
				($1.1 as? Song)?.mpMediaItem()?.albumTrackNumber ?? 0 == 0
			}
			let sortedByDiscNumber = sortedByTrackNumberWithZeroAtEnd.sorted {
				($0.1 as? Song)?.mpMediaItem()?.discNumber ?? 0 <
					($1.1 as? Song)?.mpMediaItem()?.discNumber ?? 0
			}
			// As of iOS 14.0 beta 5, MediaPlayer reports unknown disc numbers as 1, so there's no need to move disc 0 to the end.
			return sortedByDiscNumber
			
		default:
			print("The user tried to sort by “\(sortOptionLocalizedName ?? "")”, which isn’t a supported option. It might be misspelled.")
			return indexPathsAndItemsImmutable // Otherwise, the app will crash when it tries to call moveRowsUpToEarliestRow on an empty array. Escaping here is easier than changing the logic to use optionals.
		}
	}
	
}
