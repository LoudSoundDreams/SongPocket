//
//  UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-06.
//

import UIKit

extension UITableView {
	
	final func performBatchUpdates(
		sections: BatchUpdates<Int>,
		rows: [BatchUpdates<IndexPath>],
		completion: (() -> Void)? = nil
	) {
		let rowsToDelete = rows.flatMap { $0.toDelete }
		let rowsToInsert = rows.flatMap { $0.toInsert }
		let rowsToMove = rows.flatMap { $0.toMove }
		
		performBatchUpdates {
			deleteSections(IndexSet(sections.toDelete), with: .middle)
			deleteRows(at: rowsToDelete, with: .middle)
			
			insertSections(IndexSet(sections.toInsert), with: .middle)
			insertRows(at: rowsToInsert, with: .middle)
			
			// Do *not* skip `moveSection` or `moveRow` even if the old and new indices are the same.
			sections.toMove.forEach { (sourceIndex, destinationIndex) in
				moveSection(sourceIndex, toSection: destinationIndex)
			}
			rowsToMove.forEach { (sourceIndexPath, destinationIndexPath) in
				moveRow(at: sourceIndexPath, to: destinationIndexPath)
			}
		} completion: { _ in
			completion?()
		}
	}
	
	// MARK: - Sections
	
	final func allSections() -> [Int] {
		return Array(0 ..< numberOfSections)
	}
	
	// MARK: - IndexPaths
	
	final var indexPathsForVisibleRowsNonNil: [IndexPath] {
		return indexPathsForVisibleRows ?? []
	}
	
	final var indexPathsForSelectedRowsNonNil: [IndexPath] {
		return indexPathsForSelectedRows ?? []
	}
	
	final func allIndexPaths() -> [IndexPath] {
		let result = allSections().flatMap { section in
			indexPathsForRows(inSection: section, firstRow: 0)
		}
		return result
	}
	
	final func indexPathsForRows(
		inSection section: Int,
		firstRow: Int
	) -> [IndexPath] {
		let lastRow = numberOfRows(inSection: section) - 1
		guard lastRow >= 0 else {
			// The section has 0 rows.
			return []
		}
		return indexPathsForRows(
			inSection: section,
			firstRow: firstRow,
			lastRow: lastRow)
	}
	
	private func indexPathsForRows(
		inSection section: Int,
		firstRow: Int,
		lastRow: Int
	) -> [IndexPath] {
		let rows = Array(firstRow ... lastRow)
		let result = rows.map { IndexPath(row: $0, section: section) }
		return result
	}
	
	// MARK: - Deselecting
	
	final func deselectAllRows(animated: Bool) {
		indexPathsForSelectedRowsNonNil.forEach {
			deselectRow(at: $0, animated: animated) // As of iOS 14.2 developer beta 1, this doesn't animate for some reason. It works right on iOS 13.5.1.
		}
	}
	
}
