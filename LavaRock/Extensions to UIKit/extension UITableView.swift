//
//  extension UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-06.
//

import UIKit

extension UITableView {
	
	// MARK: - Asking About Selected IndexPaths
	
	// Returns whether a command that "floats" the selected rows to the top of their section, keeping them in the same order, should be allowed.
	// Returns true only if one or more rows are selected, and they're all in the same section.
	// Note: Currently identical to shouldAllowMovingSelectedRowsToBottomOfSection().
	final func shouldAllowMovingSelectedRowsToTopOfSection() -> Bool {
		guard
			let selectedIndexPaths = indexPathsForSelectedRows,
			selectedIndexPaths.count >= 1
		else {
			return false
		}
		return !isFromMultipleSections(selectedIndexPaths)
	}
	
	// Returns whether a command that "sinks" the selected rows to the bottom of their section, keeping them in the same order, should be allowed.
	// Returns true only if one or more rows are selected, and they're all in the same section.
	// Note: Currently identical to shouldAllowMovingSelectedRowsToTopOfSection().
	final func shouldAllowMovingSelectedRowsToBottomOfSection() -> Bool {
		guard
			let selectedIndexPaths = indexPathsForSelectedRows,
			selectedIndexPaths.count >= 1
		else {
			return false
		}
		return !isFromMultipleSections(selectedIndexPaths)
	}
	
	// Returns whether a command that sorts the selected rows should be allowed.
	// You should only be allowed to sort contiguous items within the same section. Therefore:
	// - If any rows are selected, this method returns whether they're in the same section and contiguous.
	// - If no rows are selected, this method returns whether you could sort all the rows; i.e., whether the table view has exactly 1 section.
	final func shouldAllowSorting() -> Bool {
		if let selectedIndexPaths = indexPathsForSelectedRows { // If any rows are selected.
			return
				!isFromMultipleSections(selectedIndexPaths) &&
				isContiguousWithinTheSameSection(selectedIndexPaths)
		} else { // If no rows are selected.
			return numberOfSections == 1
		}
	}
	
	// Returns whether the IndexPaths form a block of rows all next to each other in the same section. You can provide the IndexPaths in any order.
	private func isContiguousWithinTheSameSection(_ indexPaths: [IndexPath]) -> Bool {
		guard !isFromMultipleSections(indexPaths) else {
			return false
		}
		var rowNumbers = [Int]()
		for indexPath in indexPaths {
			rowNumbers.append(indexPath.row)
		}
		return isConsecutive(rowNumbers.sorted())
	}
	
	// Returns whether an array of integers is in increasing consecutive order.
	private func isConsecutive(_ ints: [Int]) -> Bool {
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
	
	// MARK: - Moving Rows
	
	final func moveRows(
		atIndexPathsToIndexPathsIn startingAndEndingIndexPaths: [(IndexPath, IndexPath)],
		thenDeselectAll shouldDeselectAll: Bool = true
	) {
		performBatchUpdates {
			for (startingIndexPath, endingIndexPath) in startingAndEndingIndexPaths {
				moveRow(at: startingIndexPath, to: endingIndexPath)
			}
		} completion: { _ in
			if shouldDeselectAll {
				self.deselectAllRows(animated: true)
			}
		}
	}
	
	// MARK: - Taking Action on Rows
	
	final func deselectAllRows(animated: Bool) {
		guard let indexPaths = indexPathsForSelectedRows else { return }
		for indexPath in indexPaths {
			deselectRow(at: indexPath, animated: animated) // As of iOS 14.0, this doesn't animate for some reason. It works right on iOS 13.5.1.
		}
	}
	
}
