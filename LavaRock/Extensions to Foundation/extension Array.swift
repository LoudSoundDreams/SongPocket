//
//  extension Array.swift
//  LavaRock
//
//  Created by h on 2021-04-27.
//

import UIKit

extension Array {
	
	// MARK: - Higher-Order
	
	private func allNeighborsSatisfy(
		_ predicate: (_ eachElement: Element, _ nextElement: Element) -> Bool
	) -> Bool {
		let rest = dropFirst()
		
		func allNeighborsSatisfy(
			first: Element?,
			rest: ArraySlice<Element>,
			predicate: (_ eachElement: Element, _ nextElement: Element) -> Bool
		) -> Bool {
			guard
				let first = first,
				let second = rest.first
			else {
				// We've reached the end.
				return true
			}
			guard predicate(first, second) else {
				// Test case.
				return false // Short-circuit.
			}
			let newRest = rest.dropFirst()
			return allNeighborsSatisfy(
				first: second,
				rest: newRest,
				predicate: predicate)
		}
		
		return allNeighborsSatisfy(
			first: first,
			rest: rest,
			predicate: predicate)
	}
	
	// MARK: - LibraryItem
	
	mutating func reindex()
	where Element: LibraryItem {
		for index in indices {
			self[index].index = Int64(index)
		}
	}
	
	// MARK: - IndexPath
	
	// Returns whether the IndexPaths form a block of rows all next to each other in the same section. You can provide the IndexPaths in any order.
	func isContiguousWithinSameSection() -> Bool
	where Element == IndexPath {
		guard isWithinSameSection() else {
			return false
		}
		let rowIndexes = map { $0.row }
		let sortedRowIndexes = rowIndexes.sorted()
		return sortedRowIndexes.isConsecutive()
	}
	
	// Returns whether the integers you provide are in increasing consecutive order.
	private func isConsecutive() -> Bool
	where Element == Int {
		return allNeighborsSatisfy { $0 + 1 == $1 }
	}
	
	func isWithinSameSection() -> Bool
	where Element == IndexPath {
		let section = first?.section
		let result = allSatisfy { $0.section == section }
		return result
	}
	
}
