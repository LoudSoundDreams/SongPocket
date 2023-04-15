//
//  SortingTests.swift
//  LavaRockTests
//
//  Created by h on 2022-06-23.
//

import XCTest
@testable import LavaRock

class SortingTests: XCTestCase {
	override func setUpWithError() throws {
	}
	
	override func tearDownWithError() throws {
	}
	
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
		let stringsUnsorted: [String?] = [
			nil,
			"",
			"",
			nil,
			"a",
		]
		let stringsSorted: [String?] = [
			"",
			"",
			"a",
			nil,
			nil,
		]
		
		struct Thing {
			let string: String?
			let id: Int
		}
		let thingsUnsorted = stringsUnsorted.enumerated().map { index, string in
			Thing(string: string, id: index)
		}
		let thingsSorted = thingsUnsorted.sortedMaintainingOrderWhen {
			$0.string == $1.string
		} areInOrder: {
			let leftString = $0.string
			let rightString = $1.string
			// Either can be `nil`
			
			guard let rightString else {
				return true
			}
			guard let leftString else {
				return false
			}
			return leftString.precedesAlphabeticallyFinderStyle(rightString)
		}
		XCTAssertEqual(stringsSorted, thingsSorted.map { $0.string })
		XCTAssertTrue(
			thingsSorted.allNeighborsSatisfy { left, right in
				if left.string == right.string {
					return left.id < right.id
				} else {
					return true
				}
			}
		)
	}
	
	func testPerformanceExample() throws {
		self.measure {
		}
	}
}
