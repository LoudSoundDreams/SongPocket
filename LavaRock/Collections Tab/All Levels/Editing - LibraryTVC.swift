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
		
		refreshNavigationBarButtons()
		
		// Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines).
		// Otherwise, they'll stay the same size until they reload some other time, like after you edit them or they leave memory.
		tableView.performBatchUpdates(nil, completion: nil)
	}
	
	// Note: We handle rearranging in a UITableViewDataSource method.
	
	// MARK: - Moving Rows to Top
	
	@objc func moveSelectedItemsToTop() {
		moveItemsUp(
			from: tableView.indexPathsForSelectedRows,
			to: IndexPath(row: numberOfRowsAboveIndexedLibraryItems, section: 0))
	}
	
	// Note: Every IndexPath in selectedIndexPaths must be in the same section as targetIndexPath, and at or down below targetIndexPath.
	func moveItemsUp(from selectedIndexPaths: [IndexPath]?, to firstIndexPath: IndexPath) {
		
		guard
			let indexPaths = selectedIndexPaths,
			shouldAllowFloatingToTop(forIndexPaths: selectedIndexPaths)
		else {
			return
		}
		for startingIndexPath in indexPaths {
			if startingIndexPath.section != firstIndexPath.section || startingIndexPath.row < firstIndexPath.row {
				return
			}
		}
		
		let pairsToMove = dataObjectsPairedWith(
			indexPaths.sorted(),
			tableViewDataSource: indexedLibraryItems,
			rowForFirstDataSourceItem: numberOfRowsAboveIndexedLibraryItems
		) as! [(IndexPath, NSManagedObject)]
		let targetSection = firstIndexPath.section
		var targetRow = firstIndexPath.row
		for (startingIndexPath, matchingItem) in pairsToMove {
			let targetIndexPath = IndexPath(row: targetRow, section: targetSection)
			tableView.moveRow(at: startingIndexPath, to: targetIndexPath)
			tableView.deselectRow(at: targetIndexPath, animated: true) // Wait until after all the rows have moved to do this?
			
			let startingIndex = startingIndexPath.row - numberOfRowsAboveIndexedLibraryItems
			let targetIndex = targetRow - numberOfRowsAboveIndexedLibraryItems
			indexedLibraryItems.remove(at: startingIndex)
			indexedLibraryItems.insert(matchingItem, at: targetIndex)
			
			targetRow += 1
		}
		refreshNavigationBarButtons()
	}
	
	// MARK: - Sorting
	
	// Unfortunately, we can't save UIAlertActions as constant properties of LibraryTVC. They're view controllers.
	@objc func showSortOptions() {
		let alertController = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
		for sortOption in sortOptions {
			alertController.addAction(UIAlertAction(title: sortOption, style: .default, handler: sortSelectedOrAllItems))
		}
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(alertController, animated: true, completion: nil)
	}
	
	@objc func sortSelectedOrAllItems(sender: UIAlertAction) {
		guard shouldAllowSorting() else { return }
		
		// Get the rows to sort.
		let indexPathsToSort = selectedOrEnumeratedIndexPathsIn(
			section: 0,
			firstRow: numberOfRowsAboveIndexedLibraryItems,
			lastRow: tableView.numberOfRows(inSection: 0) - 1)
		
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
		//		if sortedIndexPaths.count < 40 {
		moveRowsUpToEarliestRow(sortedIndexPaths) // You could use tableView.reloadRows, but none of those animations show the individual rows moving to their destinations.
		//		} else {
		//			tableView.reloadData()
		//		}
		
		// Update the rest of the UI.
		for indexPath in indexPathsToSort {
			tableView.deselectRow(at: indexPath, animated: true)
		}
		refreshNavigationBarButtons()
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
		
		case "Track Number":
			// Actually, return the items grouped by disc number, and sorted by track number within each disc.
			// TO DO: With more songs, this gets too slow.
			let sortedByTrackNumber = indexPathsAndItems.sorted() {
				(($0.1 as? Song)?.mpMediaItem()?.albumTrackNumber ?? 0) <
					(($1.1 as? Song)?.mpMediaItem()?.albumTrackNumber ?? 0)
			}
			let sortedByTrackNumberWithZeroAtEnd = sortedByTrackNumber.sorted() {
				(($1.1 as? Song)?.mpMediaItem()?.albumTrackNumber ?? 0) == 0
			}
			let sortedByDiscNumber = sortedByTrackNumberWithZeroAtEnd.sorted() {
				(($0.1 as? Song)?.mpMediaItem()?.discNumber ?? 0) <
					(($1.1 as? Song)?.mpMediaItem()?.discNumber ?? 0)
			}
			// As of iOS 14.0 beta 5, MediaPlayer reports unknown disc numbers as 1, so there's no need to move disc 0 to the end.
			return sortedByDiscNumber
			
			
		default:
			print("The user tried to sort by “\(sortOption ?? "")”, which isn’t a supported option. It might be misspelled.")
			return indexPathsAndItems // Otherwise, the app will crash when it tries to call moveRowsUpToEarliestRow on an empty array. Escaping here is easier than changing the logic to use optionals.
		}
	}
	
}
