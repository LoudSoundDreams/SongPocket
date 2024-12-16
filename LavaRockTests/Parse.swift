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
	#expect(
		crates ==
		[
			LRCrate(title: "7", lrAlbums: [
				LRAlbum(mpidAlbum: MPIDAlbum("13")!, lrSongs: [
					LRSong(mpidSong: MPIDSong("17")!),
					LRSong(mpidSong: MPIDSong("19")!),
					LRSong(mpidSong: MPIDSong("23")!),
				]),
			]),
			LRCrate(title: "", lrAlbums: [
				LRAlbum(mpidAlbum: MPIDAlbum("41")!, lrSongs: [
					LRSong(mpidSong: MPIDSong("43")!),
				]),
			]),
		]
	)
}
