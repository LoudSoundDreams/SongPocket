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
	
	final var indexPathsForVisibleRowsNonNil: [IndexPath] {
		return indexPathsForVisibleRows ?? []
	}
	
	final var indexPathsForSelectedRowsNonNil: [IndexPath] {
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
		let rows = Array(firstRow ... lastRow)
		return rows.map { IndexPath(row: $0, section: section) }
	}
	
	// MARK: - Updating
	
	final func performBatchUpdates(
		firstReloading toReload: [IndexPath],
		with reloadAnimation: RowAnimation,
		thenMovingSections sectionUpdates: BatchUpdates<Int>,
		andRows rowUpdates: [BatchUpdates<IndexPath>],
		with moveAnimation: RowAnimation,
		completion: @escaping () -> Void
	) {
		let rowsToDelete = rowUpdates.flatMap { $0.toDelete }
		let rowsToInsert = rowUpdates.flatMap { $0.toInsert }
		let rowsToMove = rowUpdates.flatMap { $0.toMove }
		
		performBatchUpdates {
			reloadRows(at: toReload, with: reloadAnimation)
			
			deleteSections(IndexSet(sectionUpdates.toDelete), with: moveAnimation)
			deleteRows(at: rowsToDelete, with: moveAnimation)
			
			insertSections(IndexSet(sectionUpdates.toInsert), with: moveAnimation)
			insertRows(at: rowsToInsert, with: moveAnimation)
			
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
	
	final func performBatchUpdates_async(
		_ updates: (() -> Void)?
	) async -> Bool {
		await withCheckedContinuation { continuation in
			performBatchUpdates(updates) { animationsDidCompleteSuccessfully in
//				Task { await MainActor.run { // This might be necessary. https://www.swiftbysundell.com/articles/the-main-actor-attribute/
				continuation.resume(returning: animationsDidCompleteSuccessfully)
//				}}
			}
		}
	}
	
	final func deselectAllRows(animated: Bool) {
		indexPathsForSelectedRowsNonNil.forEach {
			deselectRow(at: $0, animated: animated)
		}
	}
}
