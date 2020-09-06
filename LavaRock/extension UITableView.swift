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
	*/
	
}
