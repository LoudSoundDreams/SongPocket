// MARK: - Standard library

final class WeakRef<Referencee: AnyObject> {
	weak var referencee: Referencee? = nil
	init(_ referencee: Referencee) { self.referencee = referencee }
}

extension String {
	// Don’t sort `String`s by `<`. That puts all capital letters before all lowercase letters, meaning “Z” comes before “a”.
	func precedesInFinder(_ other: Self) -> Bool {
		let comparisonResult = localizedStandardCompare(other) // The comparison method that the Finder uses
		switch comparisonResult {
			case .orderedAscending:
				return true
			case .orderedSame:
				return true
			case .orderedDescending:
				return false
		}
	}
}

extension Sequence {
	func compacted<WrappedType>() -> [WrappedType]
	where Element == Optional<WrappedType>
	{
		return compactMap { $0 }
	}
	
	func formattedAsNarrowList() -> String
	where Element == String
	{
		return formatted(.list(type: .and, width: .narrow))
	}
}

extension Array where Element: BinaryInteger {
	// Whether the integers are increasing and contiguous.
	func isConsecutive() -> Bool {
		return allNeighborsSatisfy { $0 + 1 == $1 }
	}
}

extension Array {
	func inAnyOtherOrder() -> Self
	where Element: Equatable
	{
		guard count >= 2 else { return self }
		var result: Self
		repeat {
			result = shuffled()
		} while result == self
		return result
	}
	
	func differenceInferringMoves(
		toMatch newArray: [Element],
		by areEquivalent: (_ oldItem: Element, _ newItem: Element) -> Bool
	) -> CollectionDifference<Element>
	where Element: Hashable
	{
		return newArray.difference(from: self) { oldItem, newItem in
			areEquivalent(oldItem, newItem)
		}.inferringMoves()
	}
	
	func sortedMaintainingOrderWhen(
		shouldMaintainOrder: (Element, Element) -> Bool,
		areInOrder: (Element, Element) -> Bool
	) -> Self {
		let sortedTuples = enumerated().sorted {
			if shouldMaintainOrder($0.element, $1.element) {
				return $0.offset < $1.offset
			} else {
				return areInOrder($0.element, $1.element)
			}
		}
		return sortedTuples.map { $0.element }
	}
	
	func allNeighborsSatisfy(
		_ predicate: (_ eachElement: Element, _ nextElement: Element) -> Bool
	) -> Bool {
		let rest = dropFirst() // Empty subsequence if self is empty
		return allNeighborsSatisfy(first: first, rest: rest, predicate: predicate)
		
		func allNeighborsSatisfy(
			first: Element?,
			rest: ArraySlice<Element>,
			predicate: (_ eachElement: Element, _ nextElement: Element) -> Bool
		) -> Bool {
			guard let first = first, let second = rest.first else {
				// We’ve reached the end.
				return true
			}
			guard predicate(first, second) else {
				// Test case.
				return false // Short-circuit.
			}
			let newRest = rest.dropFirst()
			return allNeighborsSatisfy(first: second, rest: newRest, predicate: predicate)
		}
	}
}

// MARK: - Foundation

extension NotificationCenter {
	// Helps callers observe each kind of `Notification` exactly once.
	final func addObserverOnce(
		_ observer: Any,
		selector: Selector,
		name: Notification.Name,
		object: Any?
	) {
		removeObserver(observer, name: name, object: object)
		addObserver(observer, selector: selector, name: name, object: object)
	}
}

// MARK: - SwiftUI

import SwiftUI

extension Color {
	static func random() -> Self {
		return Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
	}
}

extension View {
	// As of iOS 16.6, Apple Music uses this for “Recently Added”.
	func fontTitle2Bold() -> some View { font(.title2).bold() }
	
	// As of iOS 16.6, Apple Music uses this for the current song title on the now-playing screen.
	func fontHeadline_() -> some View { font(.headline) }
	
	/*
	 As of iOS 16.6, Apple Music uses this for…
	 • Genre, release year, and “Lossless” on album details views
	 • Radio show titles
	 */
	func fontCaption2Bold() -> some View { font(.caption2).bold() }
	
	// As of iOS 16.6, Apple Music uses this for artist names on song rows.
	func fontFootnote() -> some View { font(.footnote) }
	
	func fontBody_dynamicTypeSizeUpToXxxLarge() -> some View {
		return self
			.font(.body)
			.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
	}
}

// MARK: - UIKit

import UIKit

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
