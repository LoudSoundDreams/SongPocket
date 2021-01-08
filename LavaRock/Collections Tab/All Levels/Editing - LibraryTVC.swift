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
	
//	@objc final func selectAllOrNone() {
//		if
//			let selectedIndexPaths = tableView.indexPathsForSelectedRows,
//			selectedIndexPaths.count == indexedLibraryItems.count
//		{
//			tableView.deselectAllRows(animated: false)
//		} else {
//			for indexPath in tableView.indexPathsForRowsIn(
//				section: 0,
//				firstRow: numberOfRowsAboveIndexedLibraryItems)
//			{
//				tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
//			}
//		}
//
//		refreshBarButtons()
//	}
	
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
		
		let pairsToMove = tuplesOfIndexPathsAndDataObjects(
			selectedIndexPaths.sorted(),
			tableViewDataSource: indexedLibraryItems,
			rowForFirstDataSourceItem: numberOfRowsAboveIndexedLibraryItems)
		
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
		let pairsToMove = tuplesOfIndexPathsAndDataObjects(
			sortedSelectedIndexPaths,
			tableViewDataSource: indexedLibraryItems,
			rowForFirstDataSourceItem: numberOfRowsAboveIndexedLibraryItems)
		guard let targetSection = sortedSelectedIndexPaths.last?.section else { return }
		
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
		let actionSheet = UIAlertController(
			title: LocalizedString.sortBy,
			message: nil,
			preferredStyle: .actionSheet)
		for sortOption in sortOptions {
			let sortOptionTitle: String
			switch sortOption {
			case .title:
				sortOptionTitle = LocalizedString.title
			case .newestFirst:
				sortOptionTitle = LocalizedString.newestFirst
			case .oldestFirst:
				sortOptionTitle = LocalizedString.oldestFirst
			case .trackNumber:
				sortOptionTitle = LocalizedString.trackNumber
			}
			actionSheet.addAction(
				UIAlertAction(
					title: sortOptionTitle,
					style: .default,
					handler: sortSelectedOrAllItems))
		}
		actionSheet.addAction(
			UIAlertAction(
				title: LocalizedString.cancel,
				style: .cancel,
				handler: {_ in
					self.areSortOptionsPresented = false
				}
			)
		)
		actionSheet.popoverPresentationController?.barButtonItem = sortButton
		
		areSortOptionsPresented = true
		present(actionSheet, animated: true, completion: nil)
	}
	
	private func sortSelectedOrAllItems(sender: UIAlertAction) {
		guard tableView.shouldAllowSorting() else { return }
		areSortOptionsPresented = false
		
		// Get the rows to sort.
		let indexPathsToSort = tableView.selectedOrEnumeratedIndexPathsIn(
			section: 0,
			firstRow: numberOfRowsAboveIndexedLibraryItems)
		guard indexPathsToSort.count >= 1 else { return }
		
		// Get the items to sort, too.
		let selectedIndexPathsAndItems = tuplesOfIndexPathsAndDataObjects(
			indexPathsToSort,
			tableViewDataSource: indexedLibraryItems,
			rowForFirstDataSourceItem: numberOfRowsAboveIndexedLibraryItems)
		
		// Sort the rows and items together.
		let sortOptionLocalizedTitle = sender.title
		let sortedIndexPathsAndItems =
			sorted(
				selectedIndexPathsAndItems,
				bySortOptionLocalizedTitle: sortOptionLocalizedTitle)
		
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
		moveRowsUpToEarliestRow( // You could use tableView.reloadRows, but none of those animations show the individual rows moving to their destinations.
			sortedIndexPaths,
			completion: {
				self.tableView.deselectRows(at: indexPathsToSort, animated: true)
			})
		
		// Update the rest of the UI.
		refreshBarButtons()
	}
	
	// Sorting should be stable! Multiple items with the same name, disc number, or whatever property we're sorting by should stay in the same order.
	private func sorted(
		_ indexPathsAndItemsImmutable: [(IndexPath, NSManagedObject)],
		bySortOptionLocalizedTitle sortOptionLocalizedTitle: String?
	) -> [(IndexPath, NSManagedObject)] { // Make a SortOption enum.
		switch sortOptionLocalizedTitle {
		
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
			print("The user tried to sort by “\(sortOptionLocalizedTitle ?? "")”, which isn’t a supported option. It might be misspelled.")
			return indexPathsAndItemsImmutable // Otherwise, the app will crash when it tries to call moveRowsUpToEarliestRow on an empty array. Escaping here is easier than changing the logic to use optionals.
		}
	}
	
}
