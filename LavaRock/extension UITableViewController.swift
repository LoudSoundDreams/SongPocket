//
//  extension UITableViewController.swift
//  LavaRock
//
//  Created by h on 2020-05-05.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit

extension UITableViewController {
	
	// MARK: shouldAllowFloatingToTop
	
	// Returns whether a "move selected rows to top" command should be allowed on the table view.
	// Returns true only if one or more rows are selected, and they're all in the same section.
	func shouldAllowFloatingToTop() -> Bool {
		guard let selectedIndexPaths = tableView.indexPathsForSelectedRows else {
			return false
		}
		return !isFromMultipleSections(selectedIndexPaths)
	}
	
	// MARK: shouldAllowSorting
	
	// Returns whether a "sort selected or all rows" command should be allowed on the table view.
	// Sorting should only be allowed on consecutive items within one section. Therefore:
	// - If any rows are selected, this function returns whether they're in the same section and consecutive.
	// - If no rows are selected, this function returns whether you could sort all the rows; i.e., whether the table view has exactly 1 section.
	func shouldAllowSorting() -> Bool {
		if let selectedIndexPaths = tableView.indexPathsForSelectedRows { // If any rows are selected.
			return (!isFromMultipleSections(selectedIndexPaths)
				&& isConsecutive(selectedIndexPaths))
		} else { // If no rows are selected.
			return tableView.numberOfSections == 1
		}
	}
	
	// MARK: isConsecutive
	
	// Returns whether an array of IndexPaths is in increasing consecutive order.
	// WARNING: Only works for IndexPaths in the same section.
	func isConsecutive(_ rows: [IndexPath]) -> Bool {
		var rowNumbers = [Int]()
		for indexPath in rows {
			rowNumbers.append(indexPath.row)
		}
		return isConsecutive(rowNumbers.sorted())
	}
	
	// Returns whether an array of integers is in increasing consecutive order.
	func isConsecutive(_ ints: [Int]) -> Bool {
		if ints.count <= 1 {
			return true
		} else if ints[0] + 1 != ints[1] {
			return false
		} else {
			var intsCopy = ints
			intsCopy.remove(at: 0)
			return isConsecutive(intsCopy)
		}
	}
	
	// MARK: isFromMultipleSections
	
	// Returns whether the array contains IndexPaths from multiple sections.
	func isFromMultipleSections(_ indexPaths: [IndexPath]) -> Bool {
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
	
	// MARK: indexPathsEnumeratedIn
	
	func indexPathsEnumeratedIn(section: Int, firstRow: Int, lastRow: Int) -> [IndexPath] {
		var result = [IndexPath]()
		for row in firstRow...lastRow {
			result.append(IndexPath(row: row, section: section))
		}
		return result
	}
	
	// MARK: selectedOrAllRowsInOrder
	
	func selectedOrAllRowsInOrder(numberOfRows: Int) -> [Int] {
		var result = [Int]()
		if let selectedIndexPaths = tableView.indexPathsForSelectedRows?.sorted() {
			for indexPath in selectedIndexPaths {
				result.append(indexPath.row)
			}
		} else {
			for row in 0..<numberOfRows {
				result.append(row)
			}
		}
		return result
	}
	
	// MARK: dataObjectsPairedWith
	
	// Takes an array of selected IndexPaths and the entire data source for your table view. Returns an array of tuples, each matching one of those IndexPaths with its corresponding data object from the data source.
	// WARNING: Only works for IndexPaths in the same section.
	func dataObjectsPairedWith(_ indexPaths: [IndexPath], tableViewDataSource: [Any]) -> [(IndexPath, Any)] {
		var result = [(IndexPath, Any)]()
		for indexPath in indexPaths {
			result.append((indexPath, tableViewDataSource[indexPath.row]))
		}
		return result
	}
	
	// MARK: dataObjectsFor
	
	// Takes an array of selected IndexPaths and the entire data source for your table view. Returns the data objects associated with the selected items.
	// WARNING: Only works for IndexPaths in the same section.
	func dataObjectsFor(selectedIndexPaths: [IndexPath], tableViewDataSource: [Any]) -> [Any] {
		var result = [Any]()
		for indexPath in selectedIndexPaths {
			result.append(tableViewDataSource[indexPath.row])
		}
		return result
	}
	
	// MARK: moveRowsUpToEarliestRow
	
	// Moves the rows at the given IndexPaths into a consecutive group of rows, starting at the earliest of the given IndexPaths. Provide the rows in the order you want them to end up in.
	// For example, if you provide [[0,5], [0,1], [0,3], [0,6]], the earliest IndexPath is [0,1]. This function moves the row that was at [0,5] to [0,1], the row that was at [0,1] to [0,2], the row that was at [0,3] to [0,3], and the row that was at [0,6] to [0,4], shifting the rows that were at [0,2] and [0,4] down to [0,5] and [0,6], respectively.
	// NOTE: Only works for IndexPaths in the same section.
	func moveRowsUpToEarliestRow(_ indexPaths: [IndexPath]) {
		guard !isFromMultipleSections(indexPaths) else {
			return
		}
		var firstIndexPath = indexPaths[0] // Default value
		for indexPath in indexPaths {
			if indexPath < firstIndexPath {
				firstIndexPath = indexPath // Modify value
			}
		}
		moveRowsUpToEarliestRow(from: indexPaths, startingAt: firstIndexPath)
	}
	
	// Moves rows from the given IndexPaths into consecutive order, starting at the given starting IndexPath.
	// NOTE: Only works for IndexPaths in the same section.
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
