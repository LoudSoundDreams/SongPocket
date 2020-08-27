//
//  Editing (LibraryTVC).swift
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
	
	// MARK: Rearranging
	
	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		let itemBeingMoved = activeLibraryItems[fromIndexPath.row]
		activeLibraryItems.remove(at: fromIndexPath.row)
		activeLibraryItems.insert(itemBeingMoved, at: to.row)
		refreshNavigationBarButtons() // If you made selected items non-consecutive, that should disable the Sort button. If you made selected items consecutive, that should enable the Sort button.
	}
	
	// MARK: Moving Rows to Top
	
	@objc func moveSelectedItemsToTop() {
		moveItemsUp(from: tableView.indexPathsForSelectedRows, to: IndexPath(row: 0, section: 0))
	}
	
	// NOTE: Every IndexPath in selectedIndexPaths must be in the same section as targetIndexPath, and at or down below targetIndexPath.
	func moveItemsUp(from selectedIndexPaths: [IndexPath]?, to firstIndexPath: IndexPath) {
		
		guard
			let indexPaths = selectedIndexPaths,
			shouldAllowFloatingToTop(indexPathsForSelectedRows: selectedIndexPaths)
		else {
			return
		}
		for indexPath in indexPaths {
			if indexPath.section != firstIndexPath.section || indexPath.row < firstIndexPath.row {
				return
			}
		}
		
		let pairsToMove = dataObjectsPairedWith(indexPaths.sorted(), tableViewDataSource: activeLibraryItems) as! [(IndexPath, NSManagedObject)]
		let targetSection = firstIndexPath.section
		var targetRow = firstIndexPath.row
		for (indexPath, libraryItem) in pairsToMove {
			tableView.moveRow(at: indexPath, to: IndexPath(row: targetRow, section: targetSection))
			activeLibraryItems.remove(at: indexPath.row)
			activeLibraryItems.insert(libraryItem, at: targetRow)
			tableView.deselectRow(at: IndexPath(row: targetRow, section: targetSection), animated: true) // Wait until after all the rows have moved to do this?
			targetRow += 1
		}
		refreshNavigationBarButtons()
	}
	
	// MARK: Sorting
	
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
		// Get the rows to sort.
		let selectedIndexPaths = selectedOrAllIndexPathsSortedIn(section: 0, firstRow: 0, lastRow: activeLibraryItems.count - 1)
		
		// Continue in a separate function. This lets SongsTVC override the current function to hack selectedIndexPaths. This is bad practice.
		sortSelectedOrAllItemsPart2(selectedIndexPaths: selectedIndexPaths, sender: sender)
	}
	
	func sortSelectedOrAllItemsPart2(selectedIndexPaths: [IndexPath], sender: UIAlertAction) {
		
		guard shouldAllowSorting() else { return }
		
		// Get the items to sort, too.
		let selectedIndexPathsAndItems = dataObjectsPairedWith(selectedIndexPaths, tableViewDataSource: activeLibraryItems) as! [(IndexPath, NSManagedObject)]
		
		// Sort the rows and items together.
		let sortOption = sender.title
		let sortedIndexPathsAndItems = sorted(indexPathsAndItems: selectedIndexPathsAndItems, by: sortOption)
		
		// Remove the selected items from the data source.
		for indexPath in selectedIndexPaths.reversed() {
			activeLibraryItems.remove(at: indexPath.row)
		}
		
		// Put the sorted items into the data source.
		for indexPathAndItem in sortedIndexPathsAndItems.reversed() {
			activeLibraryItems.insert(indexPathAndItem.1, at: selectedIndexPaths.first!.row)
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
		for indexPath in selectedIndexPaths {
			tableView.deselectRow(at: indexPath, animated: true)
		}
		refreshNavigationBarButtons()
	}
	
	// After editing the sort options, update this class's default sortOptions property (at the top of the file) to include all the options.
	// Sorting should be stable! Multiple items with the same name, year, or whatever property we're sorting by should stay in the same order.
	func sorted(indexPathsAndItems: [(IndexPath, NSManagedObject)], by sortOption: String?) -> [(IndexPath, NSManagedObject)] { // Make a SortOption enum.
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
