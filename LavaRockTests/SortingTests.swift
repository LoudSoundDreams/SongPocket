//
//  SortingTests.swift
//  LavaRockTests
//
//  Created by h on 2022-06-23.
//

import XCTest
@testable import LavaRock

class SortingTests: XCTestCase {
	func textLexical() {
		let lexical: [String?] = [
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
		XCTAssertTrue(lexical.allNeighborsSatisfy { left, right in
			guard let right else { return true }
			guard let left else { return false }
			return left.precedesAlphabeticallyFinderStyle(right)
		})
	}
	
	struct IdentifiableString {
		let string: String?
		let id: Int
	}
	
	func testStable() {
		let input: [String?] = [
			nil,
			"",
			"",
			nil,
			"a",
		]
		let expected: [String?] = [
			"",
			"",
			"a",
			nil,
			nil,
		]
		
		let before = input.enumerated().map { (index, string) in
			IdentifiableString(string: string, id: index)
		}
		let after = before.sortedMaintainingOrderWhen {
			$0.string == $1.string
		} areInOrder: {
			let left = $0.string
			let right = $1.string
			// Either can be `nil`
			guard let right else { return true }
			guard let left else { return false }
			return left.precedesAlphabeticallyFinderStyle(right)
		}
		
		XCTAssertEqual(expected, after.map { $0.string })
		XCTAssertTrue(after.allNeighborsSatisfy { left, right in
			if left.string == right.string {
				return left.id < right.id
			} else {
				if left.string == nil { return right.string == nil }
				// Below, assume left string is non-nil
				if right.string == nil { return true }
				// Below, assume right string is non-nil
				return left.string!.precedesAlphabeticallyFinderStyle(right.string!)
			}
		})
	}
}
