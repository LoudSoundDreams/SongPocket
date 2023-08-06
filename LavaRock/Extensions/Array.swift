//
//  Array.swift
//  LavaRock
//
//  Created by h on 2021-04-27.
//

import UIKit
import OSLog

extension Array where Element: LibraryItem {
	// Needs to match the property observer on `LibraryGroup.items`.
	mutating func reindex()
	{
		enumerated().forEach { (currentIndex, libraryItem) in
			libraryItem.index = Int64(currentIndex)
		}
	}
}
extension Array where Element == Int {
	// Whether the integers are increasing and contiguous.
	func isConsecutive() -> Bool {
		return allNeighborsSatisfy { $0 + 1 == $1 }
	}
}

extension Array {
	func inAnyOtherOrder() -> Self
	where Element: Equatable
	{
		guard count >= 2 else {
			return self
		}
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
	
	mutating func replace(
		atIndices: [Int],
		withElements: [Element]
	) {
		precondition(atIndices.count == withElements.count)
		withElements.indices.forEach { counter in
			let index = atIndices[counter]
			let element = withElements[counter]
			self[index] = element
		}
	}
	
	func sortedMaintainingOrderWhen(
		areEqual: (Element, Element) -> Bool,
		areInOrder: (Element, Element) -> Bool
	) -> Self {
		let sortedTuples = enumerated().sorted {
			if areEqual($0.element, $1.element) {
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
		
		func allNeighborsSatisfy(
			first: Element?,
			rest: ArraySlice<Element>,
			predicate: (_ eachElement: Element, _ nextElement: Element) -> Bool
		) -> Bool {
			guard
				let first = first,
				let second = rest.first
			else {
				// We’ve reached the end.
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
}
