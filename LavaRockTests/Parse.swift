// 2024-09-01

import Testing
@testable import LavaRock

private let badStructure: String = """
	1
		2
	3
5
7
	11
	13
		17
		. one tab on the next line
	
		19
		23
	29
31

	37
	41
		43
47
	53
		//
"""
@Test private func parseBadStructure() {
	let crates = Parser(badStructure).parse_crates()
	let _ = crates
	#expect(
		true
		/*
		 crates == [
		 ]
		 
		 crate 7
		 album 13
		 song 17
		 song 19
		 song 23
		 crate ""
		 album 41
		 song 43
		*/
	)
}
