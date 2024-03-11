//
//  UIKit.swift
//  LavaRock
//
//  Created by h on 2020-08-06.
//

import UIKit

extension UIViewController {
	final func dismiss__async(animated: Bool) async {
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
		var oldToDelete: [Int] = []
		var newToInsert: [Int] = []
		var toMove: [(old: Int, new: Int)] = []
		
		forEach { change in
			// If a `Change`’s `associatedWith:` value is non-`nil`, then it has a counterpart `Change` in the `CollectionDifference`, and the two `Change`s together represent a move, rather than a remove and an insert.
			switch change {
				case .remove(let offset, _, let associatedOffset):
					if let associatedOffset = associatedOffset {
						toMove.append(
							(old: offset, new: associatedOffset)
						)
					} else {
						oldToDelete.append(offset)
					}
				case .insert(let offset, _, let associatedOffset):
					if associatedOffset == nil {
						newToInsert.append(offset)
					}
			}
		}
		
		return BatchUpdates(
			toDelete: oldToDelete,
			toInsert: newToInsert,
			toMove: toMove)
	}
}

extension UITableView {
	final func allSections() -> [Int] {
		return Array(0 ..< numberOfSections)
	}
	
	final var selectedIndexPaths: [IndexPath] {
		return indexPathsForSelectedRows ?? []
	}
	
	final func allIndexPaths() -> [IndexPath] {
		return allSections().flatMap { section in
			indexPathsForRows(section: section, firstRow: 0)
		}
	}
	
	final func indexPathsForRows(section: Int, firstRow: Int) -> [IndexPath] {
		let lastRow = numberOfRows(inSection: section) - 1
		guard lastRow >= 0 else {
			// The section has 0 rows.
			return []
		}
		return (firstRow...lastRow).map { row in
			IndexPath(row: row, section: section)
		}
	}
	
	final func applyBatchUpdates(
		_ batchUpdates: BatchUpdates<IndexPath>,
		completion: @escaping () -> Void
	) {
		performBatchUpdates {
			// If necessary, call `reloadRows` first.
			deleteRows(at: batchUpdates.toDelete, with: .middle)
			insertRows(at: batchUpdates.toInsert, with: .middle)
			// Do _not_ skip `moveRow` even if the old and new indices are the same.
			batchUpdates.toMove.forEach { (source, destination) in
				moveRow(at: source, to: destination)
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
