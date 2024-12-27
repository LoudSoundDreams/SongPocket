// 2024-09-01

import Testing
@testable import LavaRock

private let only_newline = "\n"
@Test private func parse_1() {
	let output = Parser(only_newline).parse_albums()
	let correct: [LRAlbum] = []
	#expect(are_equivalent(output, correct))
}

private let bad_1: String = """
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
@Test private func parse_2() {
	let output = Parser(bad_1).parse_albums()
	let correct: [LRAlbum] = [
		LRAlbum(
			uAlbum: 7,
			uSongs: [11, 13, 29]
		),
		LRAlbum(
			uAlbum: 31,
			uSongs: [37, 41]
		),
		LRAlbum(
			uAlbum: 47,
			uSongs: [53]
		),
	]
	#expect(are_equivalent(output, correct))
}

private func are_equivalent(
	_ these: [LRAlbum],
	_ those: [LRAlbum]
) -> Bool {
	let zipped = zip(these, those)
	return zipped.allSatisfy { this, that in
		guard this.uAlbum == that.uAlbum else { return false }
		let uSongs_zipped = zip(this.uSongs, that.uSongs)
		return uSongs_zipped.allSatisfy { $0 == $1 }
	}
}
