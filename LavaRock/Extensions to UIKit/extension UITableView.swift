//
//  extension UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-06.
//

import UIKit

extension UITableView {
	
	// MARK: - Asking About Selected IndexPaths
	
	final var indexPathsF0rSelectedRows: [IndexPath] {
		return indexPathsForSelectedRows ?? [IndexPath]()
	}
	
	// MARK: - Getting IndexPaths
	
	final func allIndexPaths() -> [IndexPath] {
		var result = [IndexPath]()
		for section in 0 ..< numberOfSections {
			let indexPathsInSection = indexPathsForRows(inSection: section, firstRow: 0)
			result.append(contentsOf: indexPathsInSection)
		}
		return result
	}
	
	final func indexPathsForRows(inSection section: Int, firstRow: Int) -> [IndexPath] {
		let lastRow = numberOfRows(inSection: section) - 1
		guard lastRow >= 0 else {
			return [IndexPath]()
		}
		return indexPathsForRows(
			inSection: section,
			firstRow: firstRow,
			lastRow: lastRow)
	}
	
	private func indexPathsForRows(inSection section: Int, firstRow: Int, lastRow: Int) -> [IndexPath] {
		var result = [IndexPath]()
		for row in firstRow ... lastRow {
			result.append(IndexPath(row: row, section: section))
		}
		return result
	}
	
	// MARK: - Taking Action on Rows
	
	final func deselectAllRows(animated: Bool) {
		for indexPath in indexPathsF0rSelectedRows {
			deselectRow(at: indexPath, animated: animated) // As of iOS 14.2 beta 1, this doesn't animate for some reason. It works right on iOS 13.5.1.
		}
	}
	
}
