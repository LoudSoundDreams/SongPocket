//
//  Editing - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension LibraryTVC {
	
	override func setEditing(_ editing: Bool, animated: Bool) {
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
	
	// MARK: - Selecting All or None
	
	@objc final func selectAllOrNone() {
		if
			let selectedIndexPaths = tableView.indexPathsForSelectedRows,
			selectedIndexPaths.count == indexedLibraryItems.count
		{
			tableView.deselectAllRows(animated: false)
		} else {
			for indexPath in tableView.indexPathsEnumeratedIn(
				section: 0,
				firstRow: numberOfRowsAboveIndexedLibraryItems)
			{
				tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			}
		}
		
		refreshBarButtons()
	}
	
	// MARK: - Moving to Top
	
	@objc final func moveSelectedItemsToTop() {
		moveItemsUp(
			from: tableView.indexPathsForSelectedRows,
			to: IndexPath(row: numberOfRowsAboveIndexedLibraryItems, section: 0))
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
		
		guard let pairsToMove = dataObjectsPairedWith(
			selectedIndexPaths.sorted(),
			tableViewDataSource: indexedLibraryItems,
			rowForFirstDataSourceItem: numberOfRowsAboveIndexedLibraryItems
		) as? [(IndexPath, NSManagedObject)]
		else { return }
		
		let targetSection = firstIndexPath.section
		var targetRow = firstIndexPath.row
		var selectedAndTargetIndexPaths = [(IndexPath, IndexPath)]()
		for (selectedIndexPath, matchingItem) in pairsToMove {
			let targetIndexPath = IndexPath(row: targetRow, section: targetSection)
			selectedAndTargetIndexPaths.append(
				(selectedIndexPath, targetIndexPath))
			
			let startingIndex = selectedIndexPath.row - numberOfRowsAboveIndexedLibraryItems
			let targetIndex = targetRow - numberOfRowsAboveIndexedLibraryItems
			indexedLibraryItems.remove(at: startingIndex)
			indexedLibraryItems.insert(matchingItem, at: targetIndex)
			
			targetRow += 1
		}
		
		tableView.moveRows(
			atIndexPathsToIndexPathsIn: selectedAndTargetIndexPaths,
			completion: {
				for (_, targetIndexPath) in selectedAndTargetIndexPaths {
					self.tableView.deselectRow(at: targetIndexPath, animated: true)
				}
				self.refreshBarButtons()
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
		guard
			let pairsToMove = dataObjectsPairedWith(
				sortedSelectedIndexPaths,
				tableViewDataSource: indexedLibraryItems,
				rowForFirstDataSourceItem: numberOfRowsAboveIndexedLibraryItems
			) as? [(IndexPath, NSManagedObject)],
			let targetSection = sortedSelectedIndexPaths.last?.section
		else { return }
		
		var targetRow = tableView.numberOfRows(inSection: targetSection) - 1
		var selectedAndTargetIndexPaths = [(IndexPath, IndexPath)]()
		for (selectedIndexPath, matchingItem) in pairsToMove.reversed() {
			let targetIndexPath = IndexPath(row: targetRow, section: targetSection)
			selectedAndTargetIndexPaths.append(
				(selectedIndexPath, targetIndexPath))
			
			let startingIndex = selectedIndexPath.row - numberOfRowsAboveIndexedLibraryItems
			let targetIndex = targetRow - numberOfRowsAboveIndexedLibraryItems
			indexedLibraryItems.remove(at: startingIndex)
			indexedLibraryItems.insert(matchingItem, at: targetIndex)
			
			targetRow -= 1
		}
		
		tableView.moveRows(
			atIndexPathsToIndexPathsIn: selectedAndTargetIndexPaths,
			completion: {
				for (_, targetIndexPath) in selectedAndTargetIndexPaths {
					self.tableView.deselectRow(at: targetIndexPath, animated: true)
				}
				self.refreshBarButtons()
			}
		)
	}
	
	// MARK: - Sorting
	
	// Unfortunately, we can't save UIAlertActions as constant properties of LibraryTVC. They're view controllers.
	@objc final func showSortOptions() {
		let alertController = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
		for sortOption in sortOptions {
			alertController.addAction(UIAlertAction(title: sortOption, style: .default, handler: sortSelectedOrAllItems))
		}
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in
			self.areSortOptionsPresented = false
		}))
		
		areSortOptionsPresented = true
		present(alertController, animated: true, completion: nil)
	}
	
	private func sortSelectedOrAllItems(sender: UIAlertAction) {
		guard tableView.shouldAllowSorting() else { return }
		areSortOptionsPresented = false
		
		// Get the rows to sort.
		let indexPathsToSort = tableView.selectedOrEnumeratedIndexPathsIn(
			section: 0,
			firstRow: numberOfRowsAboveIndexedLibraryItems)
		
		// Get the items to sort, too.
		let selectedIndexPathsAndItems = dataObjectsPairedWith(
			indexPathsToSort,
			tableViewDataSource: indexedLibraryItems,
			rowForFirstDataSourceItem: numberOfRowsAboveIndexedLibraryItems
		) as! [(IndexPath, NSManagedObject)]
		
		// Sort the rows and items together.
		let sortOption = sender.title
		let sortedIndexPathsAndItems = sorted(selectedIndexPathsAndItems, by: sortOption)
		
		// Remove the selected items from the data source.
		for indexPath in indexPathsToSort.reversed() {
			indexedLibraryItems.remove(at: indexPath.row - numberOfRowsAboveIndexedLibraryItems)
		}
		
		// Put the sorted items into the data source.
		for (_, item) in sortedIndexPathsAndItems.reversed() {
			indexedLibraryItems.insert(
				item,
				at: indexPathsToSort.first!.row - numberOfRowsAboveIndexedLibraryItems)
		}
		
		// Update the table view.
		var sortedIndexPaths = [IndexPath]()
		for indexPathAndItem in sortedIndexPathsAndItems {
			sortedIndexPaths.append(indexPathAndItem.0)
		}
		moveRowsUpToEarliestRow(sortedIndexPaths) // You could use tableView.reloadRows, but none of those animations show the individual rows moving to their destinations.
		
		// Update the rest of the UI.
		for indexPath in indexPathsToSort {
			tableView.deselectRow(at: indexPath, animated: true) // TO DO: Wait until all the rows have moved to do this.
		}
		refreshBarButtons()
	}
	
	// Sorting should be stable! Multiple items with the same name, disc number, or whatever property we're sorting by should stay in the same order.
	private func sorted(_ indexPathsAndItems: [(IndexPath, NSManagedObject)], by sortOption: String?) -> [(IndexPath, NSManagedObject)] { // Make a SortOption enum.
		switch sortOption {
		
		/*
		case "Title":
		// Ignore articles ("the", "a", and "an")?
		return indexPathsAndItems.sorted(by: {
		
		// If we're sorting collections:
		($0.1.value(forKey: "title") as? String ?? "") < ($1.1.value(forKey: "title") as? String ?? "")
		
		// If we're sorting albums or songs, use the methods in `extension Album` or `extension Song` to fetch their titles (or placeholders).
		
		
		} )
		*/
		
		case "Newest First":
			let commonDate = Date()
			return indexPathsAndItems.sorted() {
				($0.1 as? Album)?.releaseDateEstimate ?? commonDate >
					($1.1 as? Album)?.releaseDateEstimate ?? commonDate
			}
			
		case "Oldest First":
			let commonDate = Date()
			return indexPathsAndItems.sorted() {
				($0.1 as? Album)?.releaseDateEstimate ?? commonDate <
					($1.1 as? Album)?.releaseDateEstimate ?? commonDate
			}
			
		case "Track Number":
			// Actually, return the items grouped by disc number, and sorted by track number within each disc.
			// TO DO: With more songs, this gets too slow.
			let sortedByTrackNumber = indexPathsAndItems.sorted() {
				($0.1 as? Song)?.mpMediaItem()?.albumTrackNumber ?? 0 <
					($1.1 as? Song)?.mpMediaItem()?.albumTrackNumber ?? 0
			}
			let sortedByTrackNumberWithZeroAtEnd = sortedByTrackNumber.sorted() {
				($1.1 as? Song)?.mpMediaItem()?.albumTrackNumber ?? 0 == 0
			}
			let sortedByDiscNumber = sortedByTrackNumberWithZeroAtEnd.sorted() {
				($0.1 as? Song)?.mpMediaItem()?.discNumber ?? 0 <
					($1.1 as? Song)?.mpMediaItem()?.discNumber ?? 0
			}
			// As of iOS 14.0 beta 5, MediaPlayer reports unknown disc numbers as 1, so there's no need to move disc 0 to the end.
			return sortedByDiscNumber
			
		default:
			print("The user tried to sort by “\(sortOption ?? "")”, which isn’t a supported option. It might be misspelled.")
			return indexPathsAndItems // Otherwise, the app will crash when it tries to call moveRowsUpToEarliestRow on an empty array. Escaping here is easier than changing the logic to use optionals.
		}
	}
	
}
