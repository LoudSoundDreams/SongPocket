import SwiftUI
import UIKit

struct Print {
	@discardableResult init(_ items: Any...) {
		let prefix = "___"
		guard !items.isEmpty else {
			print(prefix)
			return
		}
		print(prefix, items)
	}
}

final class WeakRef<Referencee: AnyObject> {
	weak var referencee: Referencee?
	init(_ referencee: Referencee) { self.referencee = referencee }
}

extension Array {
	func in_any_other_order(
		are_equivalent: (_ left: Element, _ right: Element) -> Bool
	) -> Self {
		guard count >= 2 else { return self }
		var try_number = 1
		while true {
			let result = shuffled()
			if
				!result.indices.allSatisfy({ i_result in
					are_equivalent(self[i_result], result[i_result])
				})
					|| try_number >= 42
			{ return result }
			try_number += 1
		}
	}
	
	func difference_inferring_moves(
		to_match array_target: [Element],
		by are_equivalent: (_ oldItem: Element, _ newItem: Element) -> Bool
	) -> CollectionDifference<Element>
	where Element: Hashable
	{
		return array_target.difference(from: self) { oldItem, newItem in
			are_equivalent(oldItem, newItem)
		}.inferringMoves()
	}
	
	func sorted_stably(
		should_maintain_order: (Element, Element) -> Bool,
		are_in_order: (Element, Element) -> Bool
	) -> Self {
		let tuples_sorted = enumerated().sorted {
			if should_maintain_order($0.element, $1.element) {
				return $0.offset < $1.offset
			} else {
				return are_in_order($0.element, $1.element)
			}
		}
		return tuples_sorted.map { $0.element }
	}
	
	func all_neighbors_satisfy(
		_ predicate: (_ each_element: Element, _ next_element: Element) -> Bool
	) -> Bool {
		var i_right = 1
		while i_right <= count - 1 {
			let left = self[i_right - 1]
			let right = self[i_right]
			if !predicate(left, right) { return false }
			i_right += 1
		}
		return true
	}
}

extension String {
	// Don’t sort `String`s by `<`. That puts all capital letters before all lowercase letters, meaning “Z” comes before “a”.
	func precedes_in_Finder(_ other: Self) -> Bool {
		let comparison = localizedStandardCompare(other) // The Finder uses this.
		switch comparison {
			case .orderedAscending: return true
			case .orderedSame: return true
			case .orderedDescending: return false
		}
	}
}

extension NotificationCenter {
	// Helps callers observe each kind of `Notification` exactly once.
	final func add_observer_once(_ observer: Any, selector: Selector, name: Notification.Name, object: Any?) {
		removeObserver(observer, name: name, object: object)
		addObserver(observer, selector: selector, name: name, object: object)
	}
}

extension Color {
	static func debug_random() -> Self {
		return Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
			.opacity(.one_half)
	}
}

extension UIImage {
	static var reverse: Self { sf("arrow.uturn.up") }
	static var shuffle: Self { sf("shuffle") }
	static var move_up: Self { sf("arrow.up.circle.fill") }
	static var move_down: Self { sf("arrow.down.circle.fill") }
	static var to_top: Self { sf("arrow.up.to.line") }
	static var to_bottom: Self { sf("arrow.down.to.line") }
	static func random_die() -> Self {
		return sf({
			switch Int.random(in: 1...6) {
				case 1: return "die.face.1"
				case 2: return "die.face.2"
				case 3: return "die.face.3"
				case 4: return "die.face.4"
				case 5: return "die.face.5"
				default: return "die.face.6"
			}
		}())
	}
	
	func applying_hierarchical_tint() -> UIImage? {
		return applyingSymbolConfiguration(Self.SymbolConfiguration(hierarchicalColor: .tintColor))
	}
	
	private static func sf(_ symbol_name: String) -> Self {
		return Self(systemName: symbol_name)!
	}
}

// MARK: - Table view

class LRTableViewController: UITableViewController {
	final var ids_rows_onscreen: [AnyHashable] = []
	
	// Returns a boolean indicating whether it’s safe for the caller to continue running code. If it’s `false`, table view animations are already in progress from an earlier call of this method, and callers could disrupt those animations by running further code.
	// Returns after completing the animations for moving rows, and also deselects all rows and refreshes editing buttons.
	final func apply_ids_rows(
		_ idsNew: [AnyHashable],
		running_before_continuation: (() -> Void)? = nil
	) async -> Bool {
		await withCheckedContinuation { continuation in
			_apply_ids_rows(idsNew) { should_continue in
				continuation.resume(returning: should_continue)
			}
			running_before_continuation?()
		}
	}
	private func _apply_ids_rows(
		_ new_ids: [AnyHashable],
		completion_if_should_run: @escaping (Bool) -> Void // We used to sometimes not run this completion handler, but if you wrapped this method in `withCheckedContinuation` and resumed the continuation during that handler, that leaked `CheckedContinuation`. Hence, this method always runs the completion handler, and callers should pass a completion handler that returns immediately if the parameter is `false`.
	) {
		animations_in_progress += 1
		let old_ids = ids_rows_onscreen
		ids_rows_onscreen = new_ids
		tableView.perform_batch_updates_from_ids(old: old_ids, new: new_ids) {
			// Completion handler
			self.animations_in_progress -= 1
			if self.animations_in_progress == 0 { // If we call `performBatchUpdates` multiple times quickly, executions after the first one can beat the first one to the completion closure, because they don’t have to animate any rows. Here, we wait for the animations to finish before we run the completion closure (once).
				completion_if_should_run(true)
			} else {
				completion_if_should_run(false)
			}
		}
	}
	private var animations_in_progress = 0
}

extension UITableView {
	final func indexPaths_all() -> [IndexPath] {
		return Array(0 ..< numberOfSections).flatMap { section in
			indexPaths_for_rows(section: section, row_first: 0)
		}
	}
	private func indexPaths_for_rows(section: Int, row_first: Int) -> [IndexPath] {
		let row_last = numberOfRows(inSection: section) - 1
		guard row_last >= 0 else {
			// The section has 0 rows.
			return []
		}
		return (row_first...row_last).map { row in
			IndexPath(row: row, section: section)
		}
	}
	
	final func perform_batch_updates_from_ids<Identifier: Hashable>(
		old: [Identifier], new: [Identifier],
		completion: @escaping () -> Void
	) {
		let updates = BatchUpdates(old: old, new: new)
		let section = 0
		let deletes = updates.old_to_delete.map { IndexPath(row: $0, section: section) }
		let inserts = updates.new_to_insert.map { IndexPath(row: $0, section: section) }
		let moves = updates.to_move.map { (old_row, new_row) in
			(IndexPath(row: old_row, section: section),
			 IndexPath(row: new_row, section: section))
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
		let old_to_delete: [Int]
		let new_to_insert: [Int]
		let to_move: [(old: Int, new: Int)]
		init<Identifier: Hashable>(old: [Identifier], new: [Identifier]) {
			let difference = old.difference_inferring_moves(to_match: new, by: ==)
			var deletes: [Int] = []
			var inserts: [Int] = []
			var moves: [(Int, Int)] = []
			difference.forEach { change in switch change {
					// If a `Change`’s `associatedWith:` value is non-`nil`, then it has a counterpart `Change` in the `CollectionDifference`, and the two `Change`s together represent a move, rather than a remove and an insert.
				case .remove(let offset, _, let associated):
					guard let associated else {
						deletes.append(offset)
						return
					}
					moves.append((old: offset, new: associated))
				case .insert(let offset, _, let associated):
					guard associated == nil else { return }
					inserts.append(offset)
			}}
			old_to_delete = deletes
			new_to_insert = inserts
			to_move = moves
		}
	}
}
