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
	
	// Copy of isFromMultipleSections(_:) in extension to UITableView.
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
