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
	
	func indicesOfDeletesInsertsAndMoves(
		toMatch newArray: [Element],
		by areEquivalent: (_ oldItem: Element, _ newItem: Element) -> Bool
	) -> (
		deletes: [Int],
		inserts: [Int],
		moves: [(Int, Int)]
	)
	where Element: Hashable
	{
		let difference = newArray.difference(from: self) { oldItem, newItem in
			areEquivalent(oldItem, newItem)
		}.inferringMoves()
		return difference.indicesOfDeletesInsertsAndMoves()
	}
	
	func sortedMaintainingOrderWhen(
		areEqual: (Element, Element) -> Bool,
		areInOrder: (Element, Element) -> Bool
	) -> Self {
		let sortedIndicesAndElements = enumerated().sorted {
			if areEqual($0.element, $1.element) {
				return $0.offset < $1.offset
			} else {
				return areInOrder($0.element, $1.element)
			}
		}
		return sortedIndicesAndElements.map { $0.element }
	}
	
	// MARK: Miscellaneous
	
	func sortedStably() -> Self
	where Element: Comparable
	{
		return sortedMaintainingOrderWhen(areEqual: ==, areInOrder: <)
	}
	
	// MARK: - Element: LibraryItem
	
	// Needs to match the property observer on GroupOfLibraryItems.items.
	mutating func reindex()
	where Element: LibraryItem
	{
		indices.forEach { currentIndex in
			self[currentIndex].index = Int64(currentIndex)
		}
	}
	
	// MARK: Element == IndexPath
	
	func makeDictionaryOfRowsBySection() -> [Int: [Int]]
	where Element == IndexPath
	{
		let indexPathsBySection = Dictionary(grouping: self) { $0.section }
		let result = indexPathsBySection.mapValues { indexPaths in
			indexPaths.map { $0.row }
		}
		return result
	}
	
	// Returns whether the IndexPaths form a block of rows next to each other in whatever section they're in. You can provide the IndexPaths in any order.
	func isContiguousWithinEachSection() -> Bool
	where Element == IndexPath
	{
		let rowsBySection = makeDictionaryOfRowsBySection()
		return rowsBySection.allSatisfy { (_, rows) in
			rows.sorted().isConsecutive()
		}
	}
	
	// Returns whether the integers you provide are in increasing consecutive order.
	private func isConsecutive() -> Bool
	where Element == Int
	{
		return allNeighborsSatisfy { $0 + 1 == $1 }
	}
	
	func isWithinSameSection() -> Bool
	where Element == IndexPath
	{
		let section = first?.section
		let result = allSatisfy { $0.section == section }
		return result
	}
	
}
