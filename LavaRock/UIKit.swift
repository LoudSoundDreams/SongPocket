//
//  UIKit.swift
//  LavaRock
//
//  Created by h on 2020-08-06.
//

import UIKit

extension UIViewController {
	final func dismiss__async(
		animated: Bool
	) async {
		await withCheckedContinuation { continuation in
			dismiss(animated: animated) {
				continuation.resume()
			}
		}
	}
}

struct BatchUpdates<Identifier> {
	let toDelete: [Identifier]
	let toInsert: [Identifier]
	let toMove: [(Identifier, Identifier)]
}

extension CollectionDifference {
	func batchUpdates() -> BatchUpdates<Int> {
		var indicesOfOldItemsToDelete: [Int] = []
		var indicesOfNewItemsToInsert: [Int] = []
		var indicesOfItemsToMove: [(oldIndex: Int, newIndex: Int)] = []
		
		forEach { change in
			// If a `Change`’s `associatedWith:` value is non-`nil`, then it has a counterpart `Change` in the `CollectionDifference`, and the two `Change`s together represent a move, rather than a remove and an insert.
			switch change {
				case .remove(let offset, _, let associatedOffset):
					if let associatedOffset = associatedOffset {
						indicesOfItemsToMove.append(
							(oldIndex: offset,
							 newIndex: associatedOffset)
						)
					} else {
						indicesOfOldItemsToDelete.append(offset)
					}
				case .insert(let offset, _, let associatedOffset):
					if associatedOffset == nil {
						indicesOfNewItemsToInsert.append(offset)
					}
			}
		}
		
		return BatchUpdates(
			toDelete: indicesOfOldItemsToDelete,
			toInsert: indicesOfNewItemsToInsert,
			toMove: indicesOfItemsToMove)
	}
}

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
			section: section,
			firstRow: firstRow,
			lastRow: lastRow)
	}
	private static func indexPathsForRows(
		section: Int,
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
	
	final func deselectAllRows(animated: Bool) {
		selectedIndexPaths.forEach {
			deselectRow(at: $0, animated: animated)
		}
	}
}
