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
	let mpidAlbum_13 = MPIDAlbum("13")!
	let mpidAlbum_41 = MPIDAlbum("41")!
	#expect(
		crates ==
		[
			LRCrate(
				title: "7",
				lrAlbums: [
					LRAlbum(
						mpid: mpidAlbum_13,
						lrSongs: [
							LRSong(
								mpid: MPIDSong("17")!,
								album_mpid: mpidAlbum_13),
							LRSong(
								mpid: MPIDSong("19")!,
								album_mpid: mpidAlbum_13),
							LRSong(
								mpid: MPIDSong("23")!,
								album_mpid: mpidAlbum_13),
						]),
				]),
			LRCrate(
				title: "",
				lrAlbums: [
					LRAlbum(
						mpid: mpidAlbum_41,
						lrSongs: [
							LRSong(
								mpid: MPIDSong("43")!,
								album_mpid: mpidAlbum_41),
						]),
				]),
		]
	)
}
