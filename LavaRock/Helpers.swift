// MARK: - Standard library

final class LifetimePrinter {
	init() { print(Date.now, "+", id) }
	deinit { print(Date.now, id, "-") }
	private let id = Int.random(in: 0...999)
}

final class WeakRef<Referencee: AnyObject> {
	weak var referencee: Referencee? = nil
	init(_ referencee: Referencee) { self.referencee = referencee }
}

extension Sequence {
	func compacted<WrappedType>() -> [WrappedType]
	where Element == Optional<WrappedType>
	{
		return compactMap { $0 }
	}
	
	func formatted_as_narrow_list() -> String
	where Element == String
	{
		return formatted(.list(type: .and, width: .narrow))
	}
}

extension Array {
	func in_any_other_order() -> Self
	where Element: Equatable
	{
		guard count >= 2 else { return self }
		var result: Self
		repeat {
			result = shuffled()
		} while result == self
		return result
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
		let rest = dropFirst() // Empty subsequence if self is empty
		return all_neighbors_satisfy(first: first, rest: rest, predicate: predicate)
		
		func all_neighbors_satisfy(
			first: Element?,
			rest: ArraySlice<Element>,
			predicate: (_ each_element: Element, _ next_element: Element) -> Bool
		) -> Bool {
			guard let first = first, let second = rest.first else {
				// We’ve reached the end.
				return true
			}
			guard predicate(first, second) else {
				// Test case.
				return false // Short-circuit.
			}
			let new_rest = rest.dropFirst()
			return all_neighbors_satisfy(first: second, rest: new_rest, predicate: predicate)
		}
	}
}

// MARK: - Foundation

extension NotificationCenter {
	// Helps callers observe each kind of `Notification` exactly once.
	final func add_observer_once(_ observer: Any, selector: Selector, name: Notification.Name, object: Any?) {
		removeObserver(observer, name: name, object: object)
		addObserver(observer, selector: selector, name: name, object: object)
	}
}

// MARK: - SwiftUI

import SwiftUI

extension Color {
	static func random_translucent() -> Self {
		return Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
			.opacity(.one_half)
	}
}

extension View {
	// As of iOS 16.6, Apple Music uses this for “Recently Added”.
	func font_title2_bold() -> some View { font(.title2).bold() }
	
	// As of iOS 16.6, Apple Music uses this for the current song title on the “now playing” screen.
	func font_headline_() -> some View { font(.headline) }
	
	/*
	 As of iOS 16.6, Apple Music uses this for…
	 • Genre, release year, and “Lossless” on album details views
	 • Radio show titles
	 */
	func font_caption2_bold() -> some View { font(.caption2).bold() }
	
	// As of iOS 16.6, Apple Music uses this for artist names on song rows.
	func font_footnote() -> some View { font(.footnote) }
	
	func font_body_dynamicType_up_to_xxxLarge() -> some View {
		return self
			.font(.body)
			.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
	}
}

// MARK: - UIKit

import UIKit

extension UIImage {
	static func random_die() -> Self {
		return Self(systemName: {
			switch Int.random(in: 1...6) {
				case 1: return "die.face.1"
				case 2: return "die.face.2"
				case 3: return "die.face.3"
				case 4: return "die.face.4"
				case 5: return "die.face.5"
				default: return "die.face.6"
			}
		}())!
	}
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
