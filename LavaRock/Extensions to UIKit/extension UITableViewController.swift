//
//  extension UITableViewController.swift
//  LavaRock
//
//  Created by h on 2020-05-05.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit

extension UITableViewController {
	
	// MARK: - Asking About Selected IndexPaths
	
	// Returns false if all the IndexPaths you provide have the same value for their "section" parameter. Returns true if any one or more of the IndexPaths you provide has a different value for its "section" parameter than all the others.
	private func isFromMultipleSections(_ indexPaths: [IndexPath]) -> Bool {
		if indexPaths.count <= 1 { // Terminating case.
			return false
		} else if indexPaths[0].section != indexPaths[1].section { // Test case.
			return true
		} else { // Recursive case.
			var restOfSelectedIndexPaths = indexPaths
			restOfSelectedIndexPaths.remove(at: 0)
			return isFromMultipleSections(restOfSelectedIndexPaths)
		}
	}
	
	// MARK: - Getting IndexPaths
	
	final func selectedOrEnumeratedIndexPathsIn(section: Int, firstRow: Int, lastRow: Int) -> [IndexPath] {
		if let selectedIndexPaths = tableView.indexPathsForSelectedRows?.sorted() {
			return selectedIndexPaths
		} else {
			return indexPathsEnumeratedIn(
				section: section,
				firstRow: firstRow,
				lastRow: lastRow)
		}
	}
	
	final func indexPathsEnumeratedIn(section: Int) -> [IndexPath] {
		return indexPathsEnumeratedIn(
			section: section,
			firstRow: 0,
			lastRow: tableView.numberOfRows(inSection: section) - 1)
	}
	
	final func indexPathsEnumeratedIn(section: Int, firstRow: Int, lastRow: Int) -> [IndexPath] {
		guard lastRow >= firstRow else {
			return [IndexPath]()
		}
		var result = [IndexPath]()
		for row in firstRow...lastRow {
			result.append(IndexPath(row: row, section: section))
		}
		return result
	}
	
	// MARK: - Getting Data Objects
	
	// Takes an array of selected IndexPaths and the entire data source for your table view. Returns an array of tuples, each matching one of those IndexPaths with its corresponding data object from the data source.
	// WARNING: Only works for IndexPaths in the same section.
	final func dataObjectsPairedWith(
		_ indexPaths: [IndexPath],
		tableViewDataSource: [Any],
		rowForFirstDataSourceItem: Int
	) -> [(IndexPath, Any)] {
		var result = [(IndexPath, Any)]()
		for indexPath in indexPaths {
			result.append((indexPath, tableViewDataSource[indexPath.row - rowForFirstDataSourceItem]))
		}
		return result
	}
	
	// Takes an array of selected IndexPaths and the entire data source for your table view. Returns the data objects associated with the selected items.
	// Note: Only works for IndexPaths in the same section.
	final func dataObjectsFor(
		selectedIndexPaths: [IndexPath],
		tableViewDataSource: [Any],
		rowForFirstDataSourceItem: Int
	) -> [Any] {
		guard !isFromMultipleSections(selectedIndexPaths) else {
			fatalError("Someone called dataObjectsFor(selectedIndexPaths:tableViewDataSource:rowForFirstDataSourceItem:) to get the data objects for the selected rows in a UITableView, but the selected rows were from multiple sections. This method only works for rows within the same section.")
		}
		var result = [Any]()
		for indexPath in selectedIndexPaths {
			result.append(tableViewDataSource[indexPath.row - rowForFirstDataSourceItem])
		}
		return result
	}
	
	// MARK: - Moving Rows
	
	// Moves the rows at the given IndexPaths into a consecutive group of rows, starting at the earliest of the given IndexPaths. Provide the rows in the order you want them to end up in.
	// For example, if you provide [[0,5], [0,1], [0,3], [0,6]], the earliest IndexPath is [0,1]. This function moves the row that was at [0,5] to [0,1], the row that was at [0,1] to [0,2], the row that was at [0,3] to [0,3], and the row that was at [0,6] to [0,4], shifting the rows that were at [0,2] and [0,4] down to [0,5] and [0,6], respectively.
	// Note: Only works for IndexPaths in the same section.
	final func moveRowsUpToEarliestRow(_ indexPaths: [IndexPath]) {
		guard !isFromMultipleSections(indexPaths) else { return }
		var firstIndexPath = indexPaths[0] // Default value
		for indexPath in indexPaths {
			if indexPath < firstIndexPath {
				firstIndexPath = indexPath // Modify value
			}
		}
		moveRowsUpToEarliestRow(from: indexPaths, startingAt: firstIndexPath)
	}
	
	// Moves rows from the given IndexPaths into consecutive order, starting at the given starting IndexPath.
	// Note: Only works for IndexPaths in the same section.
	private func moveRowsUpToEarliestRow(from indexPaths: [IndexPath], startingAt firstIndexPath: IndexPath) {
		
		guard
			indexPaths.count > 1,
			!isFromMultipleSections(indexPaths)
		else { return }
		
		tableView.moveRow(at: indexPaths[0], to: firstIndexPath)
		
		// Generate the new argument 1 for the recursive call.
		var newSortedIndexPaths = [IndexPath]()
		for indexPath in indexPaths {
			var newIndexPath = indexPath // Default value
			if indexPath.row < indexPaths[0].row {
				newIndexPath.row += 1 // Modify value
			}
			newSortedIndexPaths.append(newIndexPath)
		}
		newSortedIndexPaths.removeFirst()
		
		// Generate the new argument 2 for the recursive call.
		let newFirstIndexPath = IndexPath(row: firstIndexPath.row + 1, section: firstIndexPath.section)
		
		// Recursive call.
		moveRowsUpToEarliestRow(from: newSortedIndexPaths, startingAt: newFirstIndexPath)
		
	}
	
}
