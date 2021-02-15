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
	
	// Copy of isFromMultipleSections(_:) in an extension to UITableView.
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
	final func tuplesOfIndexPathsAndItems<T>(
		_ indexPaths: [IndexPath],
		sectionItems: [T],
		rowForFirstItem: Int
	) -> [(IndexPath, T)] {
		var result = [(IndexPath, T)]()
		for indexPath in indexPaths {
			result.append((indexPath, sectionItems[indexPath.row - rowForFirstItem]))
		}
		return result
	}
	
	// MARK: - Moving Rows
	
	// Moves the rows at the given IndexPaths into a consecutive group starting at the earliest of the given IndexPaths. Provide the rows' IndexPaths in the order you want the rows to end up in.
	// For example, if you provide [[0,5], [0,1], [0,3], [0,6]], the earliest IndexPath is [0,1]. This function moves the row that was at [0,5] to [0,1], the row that was at [0,1] to [0,2], the row that was at [0,3] to [0,3], and the row that was at [0,6] to [0,4], shifting the rows that were at [0,2] and [0,4] down to [0,5] and [0,6], respectively.
	// Note: Only works for IndexPaths in the same section.
	final func moveRowsUpToEarliestRow(
		from indexPaths: [IndexPath],
		completion: (() -> ())?
	) {
		guard
			!isFromMultipleSections(indexPaths),
			let firstTargetIndexPath = indexPaths.min()
		else { return }
		moveRowsUpToEarliestRow(
			from: indexPaths,
			startingAt: firstTargetIndexPath,
			completion: completion)
	}
	
	// Note: Only works for IndexPaths in the same section.
	private func moveRowsUpToEarliestRow(
		from sourceIndexPaths: [IndexPath],
		startingAt targetIndexPath: IndexPath,
		completion: (() -> ())?
	) {
		guard
			sourceIndexPaths.count >= 1,
			targetIndexPath.section == sourceIndexPaths.first?.section,
			!isFromMultipleSections(sourceIndexPaths)
		else { return }
		
		tableView.performBatchUpdates {
			tableView.moveRow(at: sourceIndexPaths[0], to: targetIndexPath)
		} completion: { _ in
			if sourceIndexPaths.count == 1 {
				completion?() // For some reason, this runs before all the rows have finished moving. Meanwhile, if you set a breakpoint before this line, then it does wait until the rows have finished moving before it runs.
			}
		}
		
		// Generate the new `sourceIndexPaths` for the recursive call.
		var newSourceIndexPaths = [IndexPath]()
		for sourceIndexPath in sourceIndexPaths {
			var newSourceIndexPath = sourceIndexPath // Default value
			if sourceIndexPath.row < sourceIndexPaths[0].row {
				newSourceIndexPath.row += 1 // Modify value
			}
			newSourceIndexPaths.append(newSourceIndexPath)
		}
		newSourceIndexPaths.removeFirst()
		
		// Generate the new `firstIndexPath` for the recursive call.
		let newTargetIndexPath = IndexPath(
			row: targetIndexPath.row + 1,
			section: targetIndexPath.section)
		
		// Recursive call.
		moveRowsUpToEarliestRow(
			from: newSourceIndexPaths,
			startingAt: newTargetIndexPath,
			completion: completion)
	}
	
}
