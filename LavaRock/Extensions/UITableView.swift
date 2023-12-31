//
//  UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-06.
//

import UIKit

extension UITableView {
	// MARK: - Sections
	
	final func allSections() -> [Int] {
		return Array(0 ..< numberOfSections)
	}
	
	// MARK: IndexPaths
	
	final var selectedIndexPaths: [IndexPath] {
		return indexPathsForSelectedRows ?? []
	}
	
	final func allIndexPaths() -> [IndexPath] {
		return allSections().flatMap { section in
			indexPathsForRows(inSection: section, firstRow: 0)
		}
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
		return Self.indexPathsForRows(
			inSection: section,
			firstRow: firstRow,
			lastRow: lastRow)
	}
	
	private static func indexPathsForRows(
		inSection section: Int,
		firstRow: Int,
		lastRow: Int
	) -> [IndexPath] {
		return (firstRow ... lastRow).map { row in
			IndexPath(row: row, section: section)
		}
	}
	
	// MARK: - Updating
	
	final func applyBatchUpdates__completion(
		sectionUpdates: BatchUpdates<Int>,
		rowUpdates: [BatchUpdates<IndexPath>],
		animation: RowAnimation,
		completion: @escaping () -> Void
	) {
		let rowsToDelete = rowUpdates.flatMap { $0.toDelete }
		let rowsToInsert = rowUpdates.flatMap { $0.toInsert }
		let rowsToMove = rowUpdates.flatMap { $0.toMove }
		
		performBatchUpdates {
			// If necessary, call `reloadRows` first.
			
			deleteSections(IndexSet(sectionUpdates.toDelete), with: animation)
			deleteRows(at: rowsToDelete, with: animation)
			
			insertSections(IndexSet(sectionUpdates.toInsert), with: animation)
			insertRows(at: rowsToInsert, with: animation)
			
			// Do *not* skip `moveSection` or `moveRow` even if the old and new indices are the same.
			sectionUpdates.toMove.forEach { (sourceIndex, destinationIndex) in
				moveSection(sourceIndex, toSection: destinationIndex)
			}
			rowsToMove.forEach { (sourceIndexPath, destinationIndexPath) in
				moveRow(at: sourceIndexPath, to: destinationIndexPath)
			}
		} completion: { _ in
			completion()
		}
	}
	
	final func performBatchUpdates__async(
		_ updates: (() -> Void)?//,
//		toRunBeforeCompletion: (() -> Void)? = nil
	) async {
		let _ = await withCheckedContinuation { continuation in
			performBatchUpdates(updates) { didCompleteAnimationsSuccessfully in
				continuation.resume(returning: didCompleteAnimationsSuccessfully)
			}
//			toRunBeforeCompletion?()
		}
	}
	
	final func deselectAllRows(animated: Bool) {
		selectedIndexPaths.forEach {
			deselectRow(at: $0, animated: animated)
		}
	}
}
