// 2020-08-06

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

extension UITableView {
	final func allIndexPaths() -> [IndexPath] {
		return Array(0 ..< numberOfSections).flatMap { section in
			indexPathsForRows(section: section, firstRow: 0)
		}
	}
	private func indexPathsForRows(section: Int, firstRow: Int) -> [IndexPath] {
		let lastRow = numberOfRows(inSection: section) - 1
		guard lastRow >= 0 else {
			// The section has 0 rows.
			return []
		}
		return (firstRow...lastRow).map { row in
			IndexPath(row: row, section: section)
		}
	}
	
	final var selectedIndexPaths: [IndexPath] { indexPathsForSelectedRows ?? [] }
	final func deselectAllRows(animated: Bool) {
		selectedIndexPaths.forEach { deselectRow(at: $0, animated: animated) }
	}
	
	final func performUpdatesFromRowIdentifiers<Identifier: Hashable>(
		old: [Identifier], new: [Identifier],
		completion: @escaping () -> Void
	) {
		let updates = BatchUpdates(old: old, new: new)
		let section = 0
		let deletes = updates.oldToDelete.map { IndexPath(row: $0, section: section) }
		let inserts = updates.newToInsert.map { IndexPath(row: $0, section: section) }
		let moves = updates.toMove.map { (oldRow, newRow) in
			(IndexPath(row: oldRow, section: section),
			 IndexPath(row: newRow, section: section))
		}
		performBatchUpdates {
			// If necessary, call `reloadRows` first.
			deleteRows(at: deletes, with: .middle)
			insertRows(at: inserts, with: .middle)
			// Do _not_ skip `moveRow` even if the old and new indices are the same.
			moves.forEach { (old, new) in moveRow(at: old, to: new) }
		} completion: { _ in completion() }
	}
	private struct BatchUpdates {
		let oldToDelete: [Int]
		let newToInsert: [Int]
		let toMove: [(old: Int, new: Int)]
		init<Identifier: Hashable>(old: [Identifier], new: [Identifier]) {
			let difference = old.differenceInferringMoves(toMatch: new, by: ==)
			var deletes: [Int] = []
			var inserts: [Int] = []
			var moves: [(Int, Int)] = []
			difference.forEach { change in switch change {
					// If a `Change`’s `associatedWith:` value is non-`nil`, then it has a counterpart `Change` in the `CollectionDifference`, and the two `Change`s together represent a move, rather than a remove and an insert.
				case .remove(let offset, _, let associatedOffset):
					if let associatedOffset = associatedOffset {
						moves.append((old: offset, new: associatedOffset))
					} else {
						deletes.append(offset)
					}
				case .insert(let offset, _, let associatedOffset):
					if associatedOffset == nil {
						inserts.append(offset)
					}
			}}
			oldToDelete = deletes
			newToInsert = inserts
			toMove = moves
		}
	}
}
