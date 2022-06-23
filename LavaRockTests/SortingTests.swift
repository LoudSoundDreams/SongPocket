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
	
	func testSortStrings() throws {
		let strings = [
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
		]
		XCTAssertTrue(
			strings.allNeighborsSatisfy { left, right in
				left.precedesAlphabeticallyFinderStyle(right)
			}
		)
	}
	
	func testPerformanceExample() throws {
		self.measure {
		}
	}
}
