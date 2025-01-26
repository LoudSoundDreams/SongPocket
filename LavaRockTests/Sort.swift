// 2022-06-23

import Testing
@testable import LavaRock
import Foundation

@Test func lexical() {
	let correct: [String?] = [
		"", "", " ",
		"1", "2", "10",
		"a", "A", "z", "Z",
		nil, nil,
	]
	let passes = correct.all_neighbors_satisfy { each, next in
		if each == next { return true }
		guard let next else { return true }
		guard let each else { return false }
		return each.is_increasing_in_Finder(next)
	}
	#expect(passes)
}

private struct Numbered {
	let value: Int?
	let number: Int
	init(_ value: Int?, number: Int) {
		self.value = value
		self.number = number
	}
}
@Test func sort_stable() {
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
	let correct: [Int?] = [
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0,
		0, 0, 0,
		1,
		nil, nil, nil, nil,
		nil, nil, nil,
	]
	let before = input.enumerated().map { (offset, element) in
		Numbered(element, number: offset)
	}
	let expected = correct.enumerated().map { (offset, element) in
		Numbered(element, number: offset)
	}
	
	let after = before.sorted { left, right in
		if left.value == right.value { return false } // Important: documentation says to return `false` in this case.
		guard let val_right = right.value else { return true }
		guard let val_left = left.value else { return false }
		return val_left < val_right
	}
	
	let zipped = Array(zip(expected, after))
	let passes_sort = zipped.allSatisfy { (expect, out) in
		expect.value == out.value
	}
	#expect(passes_sort)
	
	let passes_stable = after.all_neighbors_satisfy { each, next in
		guard each.value == next.value else { return true } // Valid assumption if `passes_sort` earlier.
		return each.number < next.number
	}
	#expect(passes_stable)
}
