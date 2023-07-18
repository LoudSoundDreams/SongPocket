//
//  SortingTests.swift
//  LavaRockTests
//
//  Created by h on 2022-06-23.
//

import XCTest
@testable import LavaRock

class SortingTests: XCTestCase {
	func testSortStrings() {
		let correctlySorted: [String?] = [
			"",
			"",
			" ",
			"1",
			"2",
			"10",
			"a",
			"A",
			"z",
			"Z",
			nil,
			nil,
		]
		XCTAssertTrue(
			correctlySorted.allNeighborsSatisfy { left, right in
				guard let right else {
					return true
				}
				guard let left else {
					return false
				}
				return left.precedesAlphabeticallyFinderStyle(right)
			}
		)
	}
	
	func testSortStringsStably() {
		let input: [String?] = [
			nil,
			"",
			"",
			nil,
			"a",
		]
		let expectedOutput: [String?] = [
			"",
			"",
			"a",
			nil,
			nil,
		]
		
		struct IdentifiableString {
			let string: String?
			let id: Int
		}
		let identifiableUnsorted = input.enumerated().map { index, string in
			IdentifiableString(string: string, id: index)
		}
		let identifiableSorted = identifiableUnsorted.sortedMaintainingOrderWhen {
			$0.string == $1.string
		} areInOrder: {
			let left = $0.string
			let right = $1.string
			// Either can be `nil`
			
			guard let right else {
				return true
			}
			guard let left else {
				return false
			}
			return left.precedesAlphabeticallyFinderStyle(right)
		}
		
		XCTAssertEqual(expectedOutput, identifiableSorted.map { $0.string })
		XCTAssertTrue(
			identifiableSorted.allNeighborsSatisfy { left, right in
				if left.string == right.string {
					return left.id < right.id
				} else {
					return true
				}
			}
		)
	}
}
