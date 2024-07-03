// 2022-06-23

import XCTest
@testable import LavaRock

class SortingTests: XCTestCase {
	func textLexical() {
		let expected: [String?] = [
			"", "", " ",
			"1", "2", "10",
			"a", "A", "z", "Z",
			nil, nil,
		]
		XCTAssertTrue(expected.allNeighborsSatisfy { left, right in
			guard let right else { return true }
			guard let left else { return false }
			return left.precedesInFinder(right)
		})
	}
	
	struct Numbered {
		let name: Int?
		let id: Int
	}
	
	func testStable() {
		let input: [Int?] = [
			nil, 0, 0,
			nil, 0, 0,
			nil, 0, 0,
			nil, 0, 0,
			1,
			nil, 0, 0,
			nil, 0, 0,
			nil, 0, 0,
		]
		let expected: [Int?] = [
			0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0,
			1,
			nil, nil, nil, nil,
			nil, nil, nil,
		]
		
		let before = input.enumerated().map { (offset, name) in
			Numbered(name: name, id: offset)
		}
		let after1 = before.sortedMaintainingOrderWhen {
			$0.name == $1.name
		} areInOrder: {
			guard let right = $1.name else { return true }
			guard let left = $0.name else { return false }
			return left < right //
		}
		let after2 = before.sortedMaintainingOrderWhen {
			$0.name == $1.name
		} areInOrder: {
			guard let right = $1.name else { return true }
			guard let left = $0.name else { return false }
			return left <= right //
		}
		
		XCTAssertEqual(expected, after1.map { $0.name })
		XCTAssertEqual(expected, after2.map { $0.name })
		XCTAssertTrue(after1.allNeighborsSatisfy { left, right in
			if left.name == right.name {
				return left.id < right.id
			} else {
				if left.name == nil { return right.name == nil }
				// Below, assume left string is non-nil
				if right.name == nil { return true }
				// Below, assume right string is non-nil
				return left.name! < right.name!
			}
		})
		XCTAssertTrue(after2.allNeighborsSatisfy { left, right in
			if left.name == right.name {
				return left.id < right.id
			} else {
				if left.name == nil { return right.name == nil }
				// Below, assume left string is non-nil
				if right.name == nil { return true }
				// Below, assume right string is non-nil
				return left.name! < right.name!
			}
		})
	}
}
