// 2024-09-01
/*
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
		
	
		19
		23
	29
31
37
	41
		43
47
	53
		
"""

@Test private func parseBadStructure() {
	let crates = Parser(badStructure).crates()
	#expect(crates == [
		LRCrate(title: "7", albums: [
			LRAlbum(rawID: "13", songs: [
				LRSong(rawID: "17"),
				LRSong(rawID: "19"),
				LRSong(rawID: "23"),
			]),
		]),
		LRCrate(title: "37", albums: [
			LRAlbum(rawID: "41", songs: [
				LRSong(rawID: "43"),
			]),
		]),
	])
}
*/
