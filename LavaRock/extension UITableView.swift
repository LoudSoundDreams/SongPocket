//
//  extension UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-06.
//

import UIKit

extension UITableView {
	
	func deselectAllRows(animated: Bool) {
		guard let indexPaths = indexPathsForSelectedRows else { return }
		for indexPath in indexPaths {
			deselectRow(at: indexPath, animated: animated) // As of iOS 14.0 beta 7, this doesn't animate for some reason. It works right on iOS 13.5.1.
		}
	}
	
	/*
	func moveRows(at indexPaths: [IndexPath], to newIndexPaths: [IndexPath]) {
		guard !containsDuplicates(indexPaths) else {
			print("Something called moveRows(at:to:), but told it to move multiple rows starting from the same IndexPath, which doesn’t make sense.")
			return
		}
		guard !containsDuplicates(newIndexPaths) else {
			print("Something called moveRows(at:to:), but told it to move multiple rows to the same IndexPath, which doesn’t make sense.")
			return
		}
		let startingAndEndingIndexPaths = zip(indexPaths, newIndexPaths)
		let sortedStartingAndEndingIndexPaths = startingAndEndingIndexPaths.sorted() {
			(pair0, pair1) in
			pair0.0 < pair1.0
		}
		moveRowsHelper(startingAndEndingIndexPaths: sortedStartingAndEndingIndexPaths)
	}
	
	// WARNING: I intend this to be a helper function only. Every tuple must have a different first element, every tuple must have a different second element, and the array of tuples must be sorted by the tuples' first elements.
	private func moveRowsHelper(startingAndEndingIndexPaths: [(IndexPath, IndexPath)]) {
		guard startingAndEndingIndexPaths.count >= 1 else { return }
		let startingIndexPath = startingAndEndingIndexPaths.first!.0
		let endingIndexPath = startingAndEndingIndexPaths.first!.1
		print(startingIndexPath)
		print(endingIndexPath)
		print("")
		moveRow(at: startingIndexPath, to: endingIndexPath)
		
		guard startingAndEndingIndexPaths.count >= 2 else { return }
		var startingAndEndingIndexPathsCopy = startingAndEndingIndexPaths
		startingAndEndingIndexPathsCopy.remove(at: 0)
		if endingIndexPath <= startingIndexPath {
			moveRowsHelper(startingAndEndingIndexPaths: startingAndEndingIndexPathsCopy)
			
		} else { // We moved a row downward, so we need to adjust some of the starting IndexPaths later in the array. endingIndexPath > startingIndexPath.
			if endingIndexPath.section == startingIndexPath.section { // If we moved a row downward within the same section.
				for index in 0 ..< startingAndEndingIndexPathsCopy.count {
					let laterStartingIndexPath = startingAndEndingIndexPathsCopy[index].0
					print(laterStartingIndexPath)
//				for (laterStartingIndexPath, _) in startingAndEndingIndexPathsCopy {
					print("")
					guard
						laterStartingIndexPath.section == endingIndexPath.section,
						laterStartingIndexPath.row <= endingIndexPath.row
					else {
						moveRowsHelper(startingAndEndingIndexPaths: startingAndEndingIndexPathsCopy)
						return
					}
					startingAndEndingIndexPathsCopy[index].0.row -= 1
//					laterStartingIndexPath.row -= 1
					print("")
				}
				
			} else { // We moved a row downward into a different section.
				for index in 0 ..< startingAndEndingIndexPathsCopy.count {
					let laterStartingIndexPath = startingAndEndingIndexPathsCopy[index].0
					print(laterStartingIndexPath)
//				for (laterStartingIndexPath, _) in startingAndEndingIndexPathsCopy {
					print("")
					if laterStartingIndexPath.section < endingIndexPath.section {
						continue
					} else if
						laterStartingIndexPath.section == endingIndexPath.section,
						laterStartingIndexPath.row >= endingIndexPath.row
					{
						startingAndEndingIndexPathsCopy[index].0.row += 1
//						laterStartingIndexPath.row += 1
						continue // to the next laterStartingIndexPath
					} else { // laterStartingIndexPath.section > endingIndexPath.section
						moveRowsHelper(startingAndEndingIndexPaths: startingAndEndingIndexPathsCopy)
					}
				}
				
			}
		}
		
		
		
	}
	*/
	
	func containsDuplicates(_ indexPaths: [IndexPath]) -> Bool {
		return containsDuplicatesHelper(sortedIndexPaths: indexPaths.sorted())
	}
	
	// WARNING: I intend this to be a helper function only. The IndexPaths must be sorted.
	func containsDuplicatesHelper(sortedIndexPaths: [IndexPath]) -> Bool {
		if sortedIndexPaths.count < 2 {
			return false
		} else if sortedIndexPaths[0] == sortedIndexPaths[1] {
			return true
		} else {
			var sortedIndexPathsCopy = sortedIndexPaths
			sortedIndexPathsCopy.remove(at: 0)
			return containsDuplicatesHelper(sortedIndexPaths: sortedIndexPathsCopy)
		}
	}
	
}
