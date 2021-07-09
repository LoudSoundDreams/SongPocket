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
	
	// MARK: Diffing
	
	func indexesOfChanges(
		toMatch newArray: [Element],
		by areEquivalent: (_ oldItem: Element, _ newItem: Element) -> Bool
	) -> (
		deletes: [Int],
		inserts: [Int],
		moves: [(Int, Int)]
	)
	where Element: Hashable
	{
		if #available(iOS 15, *) { // See comment in the `else` block.
			/*
			 This is a rudimentary way of diffing two arrays to find the deletes, inserts, and moves. It's rudimentary, but it works. I shipped something similar in Songpocket 1.0.
			 For Songpocket 1.4, I replaced this with an implementation that uses CollectionDifference, but as of iPadOS 15 beta 2, Array.difference(from:by:) is crashing with "Fatal error: unsupported". So I've brought this back, hopefully temporarily.
			 */
			
			var indexesOfItemsToMove = [(oldIndex: Int, newIndex: Int)]()
			var indexesOfNewItemsToInsert = [Int]()
			
			for indexOfNewItem in newArray.indices { // For each newItem
				let newItem = newArray[indexOfNewItem]
				if let indexOfMatchingOldItem = self.firstIndex(where: { oldItem in // If there's a corresponding oldItem
					areEquivalent(oldItem, newItem)
				}) {
					// Put the old and new indexes in the "moves" array.
					indexesOfItemsToMove.append(
						(oldIndex: indexOfMatchingOldItem, newIndex: indexOfNewItem)
					)
				} else {
					// Put the index in the "inserts" array.
					indexesOfNewItemsToInsert.append(indexOfNewItem)
				}
			}
			
			var indexesOfOldItemsToDelete = [Int]()
			
			for indexOfOldItem in self.indices { // For each oldItem
				let oldItem = self[indexOfOldItem]
				if let _ = newArray.firstIndex(where: { newItem in // If there's a corresponding newItem
					areEquivalent(oldItem, newItem)
				}) {
					continue
				} else {
					// Put the index in the "deletes" array.
					indexesOfOldItemsToDelete.append(indexOfOldItem)
				}
			}
			
			return (
				indexesOfOldItemsToDelete,
				indexesOfNewItemsToInsert,
				indexesOfItemsToMove
			)
			
		} else { // iOS 14 and earlier
			
			let difference = newArray.difference(from: self) { oldItem, newItem in // As of iPadOS 15 beta 2, this crashes with "Fatal error: unsupported" in ArrayBuffer.swift.
				areEquivalent(oldItem, newItem)
			}.inferringMoves()
			
			var indexesOfOldItemsToDelete = [Int]()
			var indexesOfNewItemsToInsert = [Int]()
			
			var indexesOfItemsToMove = [(oldIndex: Int, newIndex: Int)]()
			difference.forEach { change in
				// If a Change's `associatedWith:` value is non-nil, then it has a counterpart Change in the CollectionDifference, and the two Changes together represent a move, rather than a remove and an insert.
				switch change {
				case .remove(let offset, _, let associatedOffset):
					if let associatedOffset = associatedOffset {
						indexesOfItemsToMove.append((oldIndex: offset, newIndex: associatedOffset))
					} else {
						indexesOfOldItemsToDelete.append(offset)
					}
				case .insert(let offset, _, let associatedOffset):
					if associatedOffset == nil {
						indexesOfNewItemsToInsert.append(offset)
					}
				}
			}
			
			return (
				indexesOfOldItemsToDelete,
				indexesOfNewItemsToInsert,
				indexesOfItemsToMove
			)
			
		}
	}
	
	// MARK: - Element: LibraryItem
	
	// Needs to match the property observer on SectionOfLibraryItems.items.
	mutating func reindex()
	where Element: LibraryItem
	{
		indices.forEach { currentIndex in
			self[currentIndex].index = Int64(currentIndex)
		}
	}
	
	// MARK: - Element == IndexPath
	
	// Returns whether the IndexPaths form a block of rows all next to each other in the same section. You can provide the IndexPaths in any order.
	func isContiguousWithinSameSection() -> Bool
	where Element == IndexPath
	{
		guard isWithinSameSection() else {
			return false
		}
		let rowIndexes = map { $0.row }
		let sortedRowIndexes = rowIndexes.sorted()
		return sortedRowIndexes.isConsecutive()
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
